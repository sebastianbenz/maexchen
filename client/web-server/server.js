var dgram = require('dgram');
var http = require('http');
var sys = require('sys');
var fs = require('fs');
var url = require("url");
var path = require("path");

http.createServer(function(req, res) {
  //debugHeaders(req);

  if (req.headers.accept && req.headers.accept == 'text/event-stream') {
    if (req.url == '/events') {
      sendSSE(req, res);
    } else {
      res.writeHead(404);
      res.end();
    }
  } else {
    var uri = url.parse(req.url).pathname, filename = path.join(process.cwd(), "public", uri);
      
    path.exists(filename, function(exists) {
      if(!exists) {
        res.writeHead(404, {"Content-Type": "text/plain"});
        res.write("404 Not Found\n");
        res.end();
        return;
      }
   
      if (fs.statSync(filename).isDirectory()) filename += '/index.html';
   
      fs.readFile(filename, "binary", function(err, file) {
        if(err) {        
          res.writeHead(500, {"Content-Type": "text/plain"});
          res.write(err + "\n");
          res.end();
          return;
        }
   
        res.writeHead(200);
        res.write(file, "binary");
        res.end();
      });
    });
  }
}).listen(8000);

function sendSSE(req, res) {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive'
  });

  var server = dgram.createSocket("udp4");

  server.on("error", function (err) {
    console.log("server error:\n" + err.stack);
    server.close();
  });

  var id = (new Date()).toLocaleTimeString();

  server.on("message", function (msg, rinfo) {
    console.log("server got: " + msg + " from " +
      rinfo.address + ":" + rinfo.port);
    constructSSE(res, id, msg);
  });

  server.bind(12345);

  var message = new Buffer("REGISTER_SPECTATOR;web_server");
  server.send(message, 0, message.length, 9000, "localhost", function(err, bytes) {
  });

}

function constructSSE(res, id, data) {
  res.write('id: ' + id + '\n');
  res.write("data: " + data + '\n\n');
}

function debugHeaders(req) {
  sys.puts('URL: ' + req.url);
  for (var key in req.headers) {
    sys.puts(key + ': ' + req.headers[key]);
  }
  sys.puts('\n\n');
}
