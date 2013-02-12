Connection = require 'ssh2'
fs = require 'fs'

module.exports.Updater = class Updater
  app: null
  server: null
  conf: {}
  constructor: (server, app)->
    @app = app
    @server = server
    @conf =
      username: @app.config.get 'defaultSSHUser'
      host: @server.getHostname()
      port: @app.config.get 'defaultSSHPort'
      # TODO: Make this async, we're blocking the whole app while we read the key (probably repeatedly)
      privateKey: fs.readFileSync @app.config.get 'privateKeyPath'
  getSSHLocation: ->
    @conf.username + '@' + @conf.host + ':' + @conf.port;
  createLogMessage: (data, extended)->
    log =
      server: @server.getHostname()
      stream: extended
      cssName: @server.getCSSName()
      message: data
  logMessage: (data, extended)->
    @app.emit 'serverLogMessage', @createLogMessage()
  runUpdates: (done)->
    sshConnection = new Connection()
    that = this
    sshConnection.on 'ready', ->
      sshConnection.exec @app.config.get 'defaultUpdateCommand', (error, stream)->
        if error
          that.app.log.error "Error connecting to #{that.getSSHLocation()}, updates could not be run."
          done error
        stream.on 'data', (data, extended)->
          that.app.log.log (extended === 'stderr' ? 'error' : 'info'), data
          that.logMessage.apply that, [data, extended]
        stream.on 'exit', (code, signal)->
          if code is 0
            done null
    sshConnection.connect @conf
