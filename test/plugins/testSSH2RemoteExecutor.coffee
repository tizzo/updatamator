module.exports.Updater = class Updater
  app: null
  server: null
  constructor: (server, app)->
    @app = app
    @server = server
  runUpdate: ()->
    log =
      server: 'server1.example.com'
      stream: 'stdout'
      cssName: 'server3-example-com'
    for num in [0..50]
      log.message = "message #{num}"
      app.emit 'serverLogMessage', log
