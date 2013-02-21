ssh2 = require 'ssh2'

module.exports.Updater = class Updater
  app: null
  server: null
  success: true
  constructor: (server, app)->
    @app = app
    @server = server
  # setSuccess: (success)-> @success = success
  runUpdates: (done)->
    log =
      server: @server.getHostname()
      stream: 'stdout'
      cssName: @server.getCSSName()
    for num in [0..50]
      log.message = "message #{num}"
      @app.emit 'serverLogMessage', log
    @app.emit "serverUpdateComplete::#{@server.getHostname()}", {success: true, server: this.server}
    done()
