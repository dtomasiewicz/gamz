var GamzClient = function() {
  var self = this;

  this.socket = null;
  this.onopen = null;
  this.onclose = null;
  this.onnotify = null;
  this._handlers = [];

  // private
  var dispatch = function(msg) {
    msg = JSON.parse(msg.data);
    var id = msg.shift().split('_', 2), prefix;
    msg.unshift(id[1]);
    if(id[0] == 'n') {
      if(self.onnotify) {
        self.onnotify.apply(self, msg);
      }
    } else {
      var handler = self._handlers.shift();
      if(handler) {
        handler.apply(self, msg);
      }
    }
  };

  this.open = function(options) {
    var uri;
    if(typeof options == "string") {
      uri = options;
    } else {
      var scheme, host, port, resource;
      options = options || {};
      port = options.port || 80;
      if(options.secure) {
        scheme = 'wss';
        port = port != 443 ? ':'+port : '';
      } else {
        scheme = 'ws';
        port = port != 80 ? ':'+port : '';
      }
      host = options.host || window.location.hostname;
      resource = options.resource || '';
      uri = scheme+'://'+host+port+resource.replace(/^([^\/])/, '/$1');
    }
    this.socket = new WebSocket(uri);
    this.socket.onopen = function() {
      if(self.onopen) {
        self.onopen.call(self);
      }
    };
    this.socket.onclose = function() {
      self.socket = null;
      if(self.onclose) {
        self.onclose.call(self);
      }
    };
    this.socket.onmessage = dispatch;
    return this;
  };

  this.close = function() {
    this.socket.close();
  };

  this.act = function(action, data, handler) {
    this._handlers.push(handler);
    var msg = [action].concat(data);
    this.socket.send(JSON.stringify(msg));
  };
};

var KEYCODE_RETURN = 13;
var terminal;

function print(message) {
  terminal.stdout.value += message+"\n";
  terminal.stdout.scrollTop = terminal.stdout.scrollHeight;
}

function setStatus(message) {
  terminal.status.value = terminal.activeHost+":"+terminal.activePort+" "+message;
}

function connect() {
  terminal.activeHost = terminal.host.value;
  terminal.activePort = terminal.port.value;

  setStatus('connecting...');

  terminal.client = new GamzClient();
  terminal.client.onopen = function() {
    setStatus('connected');
  };
  terminal.client.onclose = function() {
    setStatus('closed');
    terminal.client = null;
  };
  terminal.client.onnotify = function(id) {
    print('NOTIFY '+id+' => '+JSON.stringify(
      Array.prototype.slice.call(arguments, 1)
    ));
  };
  terminal.client.open({
    host: terminal.activeHost,
    port: terminal.activePort
  });
}

window.onload = function() {
  terminal = {
    stdin: document.getElementById('stdin'),
    stdout: document.getElementById('stdout'),
    status: document.getElementById('status'),
    host: document.getElementById('host'),
    port: document.getElementById('port'),
    client: null,
    activeHost: null,
    activePort: null
  };

  document.getElementById('connect').onclick = function() {
    if(terminal.client) {
      if(confirm('Close current connection?')) {
        var old = terminal.client.onclose;
        terminal.client.onclose = function(e) {
          if(old) old.call(terminal.client);
          connect();
        }
        terminal.client.close();
      }
    } else {
      connect();
    }
  };

  document.getElementById('disconnect').onclick = function() {
    if(terminal.client) {
      terminal.client.close();
    }
  }

  terminal.stdin.onkeyup = function(e) {
    if(e.keyCode == KEYCODE_RETURN) {
      if(terminal.client) {
        print('>>> '+this.value);
        var input = this.value.split(' ', 2), data;
        this.value = "";

        data = input[1] ? JSON.parse(input[1]) : [];
        terminal.client.act(input[0], data, function(res) {
          print("RESPONSE["+input[0]+"] "+res+" => "+JSON.stringify(
            Array.prototype.slice.call(arguments, 1)
          ));
        });
      }
      return false;
    }
    return true;
  };
};