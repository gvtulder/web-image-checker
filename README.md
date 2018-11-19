Web-based image reviewing tool
==============================

This is a crude web-based image reviewing tool that can be used to quickly review the results of (medical) image processing algorithms. It shows you a result (some images, a video) and lets you mark the result as correct or incorrect. It saves everything in text files.

![](docs/images/screenshot-checklist.png?raw=true)

Requirements
------------
Ruby (e.g., version 2.5), RubyGems and a recent version of Sinatra:
```
sudo apt install ruby
sudo gem install sinatra
```
After configuration (see below), start the web server with
```
rackup config.ru
```
Open http://localhost:9292/ to view some of the examples.

You can run the server with the ``rackup`` tool, but for improved performance and a more stable set-up, you might want to run it using [Nginx](https://nginx.org/) and the [Passenger module](https://www.phusionpassenger.com/).

Key concepts
------------
The viewer assumes that you have
* Tasks: these are single review units (e.g., the results of your algorithm for one subject);
* Task sets: these are sets of similar tasks (e.g., the tasks for one run of your algorithm).

Each task can contain anything that can be viewed in web browser: for example, some images, MP4 videos, an HTML fragment. The package also includes the [Papaya JavaScript-based viewer](https://github.com/rii-mango/Papaya) to show NIFTI and some other medical image formats. All tasks within a set use the same rendering template.

Each task can be reviewed and given a decision (e.g., "good" or "bad") and an optional comment. The scores for all tasks are saved as text files and can be exported in CSV format.

Defining a task set
-------
A task set named `%{set_id}` consists of three components:
* An entry in the `tasks/sets.yml` file, defining the properties of the task;
* A list of task identifiers and data  paths in a text file `tasks/%{set_id}.txt`;
* A list of decisions and comments, stored in text files named `tasks/%{set_id}/decision-%{task_id}.txt` and  `tasks/%{set_id}/comment-%{task_id}.txt`.

### `tasks/sets.yml`
This is a YAML file containing the list of task sets. Each set has the following parameters:
- `set_id`: the set identifier used in paths and URLs (keep it simple, [-a-z0-9]+)
- `title`: title for the set list (may contain HTML)
- `template`: path to the ERB template used to render the task fragments

Optional parameters include:
- `show_csv_link`: set to false to hide the CSV download link (default: true)
- `show_stable_id`: set to true to show the stable task IDs on top of the page (default: false)
- `list_stable_id`: set to true to show the stable task IDs in the task list (default: false)
- `decision_choices`: name of the decision type (see decision_choices.yml, default = default)

Any additional parameters are available through the parameters field of the set object.

### `tasks/%{set_id}.txt`
This is a text file specifying one task per line, in the following space-separated format:
```
%{task_id} %{data path} %{second data path (optional)} ...
```
* The task ID is a stable identifier of the task, e.g., the subject ID. It should be unique in the task set and should be simple enough to be used in filenames (i.e., no spaces, no special characters).
* The data path points to a path on the file system with the results for this task. It is used to render the task and to serve the files. For example, you might have a directory for a single subject with a number of images you would like to view. Alternatively, you the path can point directly to a single file.
* It is possible to specify multiple paths, separated by spaces. How this is rendered depends on the task view you choose.
* Tasks are assigned a task number based on their position in the text file. Only the task number is shown in the interface, the stable task ID is not visible unless the task view explicitly shows it. Shuffle the lines in the text file to show the tasks in random order (e.g., to do a blind review).

Task views
------------
The ERB templates in `task-views/` define how the tasks are displayed. You specify the task view for a task set in the `template` field in `tasks/sets.yml`. You can define your own template or use some of the predefined views:
* `task-views/all-images.erb` looks in the data path and renders all `.jpg` and `.png` images in the directory (or you can specify the path to the image directly);
* `task-views/all-mp4s.erb` does something similar for `.mp4` videos;
* `task-views/all-nii-gzs.erb` shows a Papaya viewer for all `.nii.gz` files in the directory;
* `task-views/nii-gz-segmentation.erb` shows a viewer with a `.nii.gz` image (first path) and a segmentation overlay (second path);
* `task-views/index-html.erb` looks for a file named `index.html` in the path and renders this (use relative `src` paths to show images in the same directory);

Decision choices
-----------------
By default, the viewer will offer a choice between `Correct` results, results that `Need fixing` and results that are `Undecided`. A custom set of choices can be defined by editing `config/decision_choices.yml` and setting the `decision_choices` option in the set definition.

Authentication
-----------------
By default, the web viewer is not protected by a password. Rename `config/auth.example.yml` to `config/auth.yml` and edit the passwords to enable HTTP basic authentication.

Nginx X-Accel-Redirect headers
-----------------
If you serve large numbers of files, or large files, it can be more efficient if you use the Nginx webserver and enable the `X-Accel-Redirect` headers to have the files served by Nginx directly. See the [Nginx documentation](https://www.nginx.com/resources/wiki/start/topics/examples/x-accel/) to enable this and then edit `config/x_accel_map.yml` to specify the mapping for the viewer.


License
-------------------

This library was written by Gijs van Tulder (https://vantulder.net/) at the
Biomedical Imaging Group Rotterdam, Erasmus MC, Rotterdam, the Netherlands
(https://www.bigr.nl/).

This code is made available under the MIT license. See ``LICENSE.txt`` for details.

https://github.com/gvtulder/web-image-checker

