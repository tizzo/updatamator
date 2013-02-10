ssh2 = require 'ssh2'

module.exports.Updater = class Updater
  app: null
  server: null
  constructor: (server, app)->
    @app = app
    @server = server
  runUpdate: ()->
