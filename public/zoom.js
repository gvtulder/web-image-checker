
// cookie helper functions from
// https://www.quirksmode.org/js/cookies.html
function createCookie(name,value,days) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
}
function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}
function eraseCookie(name) {
	createCookie(name,"",-1);
}


// zoom buttons
document.addEventListener('click', function(e) {
  var zoomFactor = null;
  if (e.target && e.target.id == 'zoom-plus-button') {
    zoomFactor = 1.1;
  } else if (e.target && e.target.id == 'zoom-minus-button') {
    zoomFactor = 1.0 / 1.1;
  }
  if (zoomFactor) {
    var imgs = document.getElementById('task-images');
    var newZoom = zoomFactor * (imgs.style.zoom ? imgs.style.zoom : 1);
    if (Math.abs(newZoom - 1) < 1e-4) {
      imgs.style.zoom = '';
      eraseCookie('zoom-factor-' + document.body.getAttribute('data-task-set-id'));
    } else {
      imgs.style.zoom = newZoom;
      createCookie('zoom-factor-' + document.body.getAttribute('data-task-set-id'), newZoom);
    }
    if (e.preventDefault) e.preventDefault();
    if (e.stopPropagation) e.stopPropagation();
    return false;
  }
});

(function() {
  var zoomFactor = readCookie('zoom-factor-' + document.body.getAttribute('data-task-set-id'));
  if (zoomFactor) {
    var imgs = document.getElementById('task-images');
    if (imgs) {
      imgs.style.zoom = zoomFactor;
    }
  }
})();

// create a list of keyboard shortcuts
var decisionsWithKeys = {};
(function() {
  var decisions = document.getElementsByName('decision');
  for (var i=0; i<decisions.length; i++) {
    if (decisions[i].getAttribute('data-shortkey')) {
      decisionsWithKeys[decisions[i].getAttribute('data-shortkey')] = decisions[i].id;
    }
  }
})();

// process keyboard shortcuts
document.addEventListener('keyup', function(e) {
  if (e.target && e.target.nodeName == 'TEXTAREA') return;

  var decision = decisionsWithKeys[e.key];
  if (decision) {
    document.getElementById(decision).checked = true;
    document.getElementById('f-btn-save-next').click();
    if (e.preventDefault) e.preventDefault();
    if (e.stopPropagation) e.stopPropagation();
    return false;
  }
});

// scroll task list to currently selected element
(function() {
  var currentTaskEl = document.getElementById('current-task-element');
  if (currentTaskEl && currentTaskEl.scrollIntoView) {
    currentTaskEl.scrollIntoView({block: 'center', inline: 'center'});
  }
})();

