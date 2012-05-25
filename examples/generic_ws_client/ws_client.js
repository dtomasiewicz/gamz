var KEYCODE_RETURN = 13;
var stdin, stdout, socket;

window.onload = function() {
  stdin = document.getElementById('stdin');
  stdout = document.getElementById('stdout');

  document.getElementById('connect').onclick = function() {
    var host = document.getElementById('host').value;
    var port = parseInt(document.getElementById('port').value);
    socket = new WebSocket('ws://'+host+':'+port);
  }

  stdin.onkeyup = function(e) {
    if(e.keyCode == KEYCODE_RETURN) {
      stdout.innerText += stdin.value;
    }
  }
}