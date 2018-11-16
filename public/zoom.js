
document.addEventListener('click', function(e) {
  if (e.target && e.target.id == 'zoom-plus-button') {
    var imgs = document.getElementById('task-images');
    if (!imgs.style.zoom) {
      imgs.style.zoom = 1.1;
    } else {
      imgs.style.zoom *= 1.1;
    }
    if (e.preventDefault) e.preventDefault();
    if (e.stopPropagation) e.stopPropagation();
    return false;
  } else if (e.target && e.target.id == 'zoom-minus-button') {
    var imgs = document.getElementById('task-images');
    if (!imgs.style.zoom) {
      imgs.style.zoom = 1.0 / 1.1;
    } else {
      imgs.style.zoom *= 1.0 / 1.1;
    }
    if (e.preventDefault) e.preventDefault();
    if (e.stopPropagation) e.stopPropagation();
    return false;
  }
});

var decisionsWithKeys = {};
(function() {
  var decisions = document.getElementsByName('decision');
  for (var i=0; i<decisions.length; i++) {
    if (decisions[i].getAttribute('data-shortkey')) {
      decisionsWithKeys[decisions[i].getAttribute('data-shortkey')] = decisions[i].id;
    }
  }
})();

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
