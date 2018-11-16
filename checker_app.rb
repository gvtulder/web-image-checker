require 'sinatra/base'
require 'yaml'
require 'base64'
require 'digest'
require 'csv'

# loads the list of available task sets from tasks/sets.yml
class TaskSets < Hash
  def initialize
    sets = YAML.load(File.read("tasks/sets.yml"))
    sets.each do |v|
      self[v["set_id"]] = TaskSet.new(v["set_id"], v["title"], v["template"], v)
    end
  end

  def self.[](set_id)
    TaskSets.new[set_id]
  end
end

# represents a single task set
class TaskSet
  attr_reader :id, :title, :template, :decision_choices, :parameters

  def initialize(id, title, template, parameters)
    @id = id
    @title = title
    @template = template
    @parameters = parameters
    @tasks = []
    File.readlines("tasks/#{ @id }.txt").each do |line|
      stable_id, *paths = line.strip.split(" ")
      @tasks << Task.new(self, @tasks.size + 1, stable_id, paths)
    end
    @decision_choices = YAML.load(File.read("config/decision_choices.yml"))[parameters["decision_choices"] || "default"]
  end

  def get_task(position)
    # returns a task by position (first task = 1)
    @tasks[position - 1]
  end

  def each(&block)
    @tasks.each do |task|
      block.call task
    end
  end

  def size
    @tasks.size
  end

  def first_task
    # returns the first task without a decision
    idx = 0
    idx += 1 while idx < @tasks.size and not @tasks[idx].decision.nil?
    @tasks[(idx < @tasks.size) ? idx : 0]
  end

  def next_task(task)
    # returns the next task after the given task without a decision
    idx = task.id % @tasks.size
    while idx != (task.id - 1) and not @tasks[idx].decision.nil?
      idx = (idx + 1) % @tasks.size
    end
    if idx == (task.id - 1)
      nil
    else
      @tasks[idx]
    end
  end
end

# a single task
class Task
  # id is the position in the item list (starting from 1)
  # stable_id is the persistent task identifier (e.g., a subject ID)
  attr :id, :stable_id, :set, :paths, :decision, :comment

  def initialize(set, id, stable_id, paths)
    @set = set
    @id = id
    @stable_id = stable_id
    @paths = paths
    @decision = read_from_file("decision")
    @comment = read_from_file("comment")
  end

  def path
    paths.first
  end

  def save_decision(decision)
    save_to_file("decision", decision)
    @decision = decision
  end

  def save_comment(comment)
    save_to_file("comment", comment)
    @comment = comment
  end

  def has_comment?
    @comment.to_s.strip.size > 0
  end

  private

  def read_from_file(type)
    filename = File.join("tasks", @set.id.to_s, "#{ type }-#{ @stable_id }.txt")
    if File.exists? filename
      File.read(filename).strip
    else
      nil
    end
  end

  def save_to_file(type, contents)
    basedir = File.join("tasks", @set.id.to_s)
    Dir.mkdir(basedir) unless File.exists? basedir
    File.open(File.join(basedir, "#{ type }-#{ @stable_id }.txt"), "w") do |f|
      f.puts contents
    end
  end
end


class CheckerApp < Sinatra::Base
  helpers do
    alias_method :h, :escape_html

    def url_for_file(task, filename, path_idx=0)
      # generates the url to relative filename (can be a relative path)
      # for the given task and path
      File.join(task.set.id.to_s, "task-data", task.id.to_s, path_idx.to_s,
                "random=" + (Time.now.to_i + rand).to_s, filename)
    end

    def rewrite_src_attributes(html, task, path_idx=0)
      # rewrites the src="..." tags in the html fragment using url_for_file
      html.gsub(/src="([^"]+)"/) do
        "src=\"#{url_for_file(task, $1, path_idx)}\""
      end
    end
  end

  not_found do
    "Not found, sorry."
  end

  use Rack::Auth::Basic do |username, password|
    if File.exists? "config/auth.yml"
      users = YAML.load(File.read("config/auth.yml"))
      not users[username].nil? and users[username] == password
    else
      true
    end
  end

  # main index
  get "/" do
    erb :index, :locals=>{:sets=>TaskSets.new}
  end

  # show a task
  get %r{/([-a-z0-9]+)} do |set_id|
    set = TaskSets[set_id] or raise Sinatra::NotFound
    current_task = params[:task] ? set.get_task(params[:task].to_i) : nil

    if current_task.nil?
      redirect to("/#{set_id}?task=#{set.first_task.id}")
    end

    erb :task, :locals=>{:set=>set, :current_task=>current_task}
  end

  # update task score
  post "/update" do
    raise Sinatra::NotFound unless params[:set] =~ /\A[-a-z0-9]+\Z/
    raise Sinatra::NotFound unless params[:task] =~ /\A[0-9]+\Z/

    set = TaskSets[params[:set]] or raise Sinatra::NotFound
    current_task = set.get_task(params[:task].to_i) or raise Sinatra::NotFound

    current_task.save_decision(params[:decision].strip) unless params[:decision].nil?
    current_task.save_comment(params[:comment].strip) unless params[:comment].nil?

    next_task = nil
    if params.has_key? "btn_save_next"
      next_task = set.next_task(current_task)
    end
    next_task = current_task if next_task.nil?

    redirect to("/#{ set.id }?task=#{ next_task.id }")
  end

  # get task scores in CSV format
  get %r{/([-a-z0-9]+)\.csv} do |set_id|
    set = TaskSets[set_id] or raise Sinatra::NotFound

    content_type "text/csv"
    CSV.generate(:force_quotes=>true) do |csv|
      csv << ["task", "stable id", "decision", "comments"]
      set.each do |task|
        csv << [task.id, task.stable_id, task.decision, task.comment.to_s.gsub(/[\r\n]/, " ")]
      end
    end
  end

  # serve a file:
  # :set_id/task-data/:task_id/:path_idx/random=12345/:filename
  get %r{/([-a-z0-9]+)/task-data/([0-9]+)/([0-9]+)/random=[^/]+/([-/._A-Za-z0-9]+)} do |set_id, task_id, path_idx, filename|
    set = TaskSets[set_id] or raise Sinatra::NotFound
    task = set.get_task(task_id.to_i) or raise Sinatra::NotFound

    # check which path we need
    path = task.paths[path_idx.to_i]
    path = File.dirname(path) if path =~ /\.html$/
    path = File.expand_path(path)

    if File.file?(path) and File.basename(path) == filename
      # the path directly points to the file
      abs_filename = path
    else
      # the path points to a directory,
      # clean up and resolve filename
      abs_filename = File.expand_path(filename, path)
      raise Sinatra::NotFound unless abs_filename.start_with? path
    end

    case filename
    when /\.jpg$/ then content_type "image/jpeg"
    when /\.png$/ then content_type "image/png"
    when /\.mp4$/ then content_type "video/mp4"
    else content_type "application/octet-stream"
    end

    # can we use Nginx's X-Accel-Redirect header?
    if File.exists? "config/x_accel_map.yml"
      x_accel_map = YAML.load(File.read("config/x_accel_map.yml"))
      x_accel_map.each do |prefix, redir|
        if path.start_with? prefix
          response["X-Accel-Redirect"] = File.join(redir, abs_filename.delete_prefix(prefix))
          halt
        end
      end
    end

    # send file by other means
    send_file abs_filename
  end
end
