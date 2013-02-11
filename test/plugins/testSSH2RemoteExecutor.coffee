module.exports.Updater = class Updater
  app: null
  server: null
  constructor: (server, app)->
    @app = app
    @server = server
  runUpdates: ()->
    log =
      server: @server.getHostname()
      stream: 'stdout'
      cssName: @server.getCSSName()
    for num in [0..50]
      log.message = "message #{num}"
      @app.emit 'serverLogMessage', log
