/**
 * DinoTrap
 * A localized game involving dinosaurs, traps, etc ...
 */

// ######## Module dependencies.

var express = require('express');
var app = module.exports = express.createServer();
var io = require('socket.io').listen(app);

// ######## Configuration

app.configure(function(){
  //app.set('views', __dirname + '/views');
  //app.set('view engine', 'jade');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
});

app.configure('development', function(){
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
});

app.configure('production', function(){
  app.use(express.errorHandler());
});


// ######## Socket.IO

io.sockets.on('connection', function (socket) {
	
  socket.on('login', function (data) {
    socket.set('name', data.name, function() {
		socket.join(data.name);
		socket.to(data.name).emit('login-accepted', {"name":data.name, "id": "123" });
	});
  });

  socket.on('placeTrap', function(data){
	console.log(data);
  });

});

// ######## Launch

app.listen(9060, function(){
  console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
});
