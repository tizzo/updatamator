IO = require 'socket.io'

module.exports.attach = (app)->
  if app.config.get('socketIOPort') == app.config.get('port')
    io = IO.listen app.server
  else
    app.log 'info', "Starting socket server on port #{app.config.get('socketIOPort')}."
    options =
      key: fs.readFileSync app.config.get('socketIOKey')
      cert: fs.readFileSync app.config.get('socketIOCert')
    handler = (req, res)->
      res.writeHead 200, {'Content-Type': 'text/plain'}
      res.end 'server running'
    socketServer = require('https').createServer(options, handler)
    IO.listen app.server
    io = IO.listen(socketServer)
    socketServer.listen(app.config.get('socketIOPort'))

  for key, value of app.config.get 'socketIOSettings'
    io.set key, value

  app.on 'serverLogMessage', (message)->
    io.sockets.emit 'serverLogMessage', message

  app.on 'serverUpdateComplete::*', (data)->
    server = data.server
    io.sockets.emit 'serverUpdateComplete',
      cssName: server.getCSSName()
      serverHostName: server.getHostname()


  io.sockets.on 'connection', (socket)->
    socket.on 'runUpdate', (packageString)->
      app.emit 'runUpdate', packageString

