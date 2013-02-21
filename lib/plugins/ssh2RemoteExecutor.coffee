Connection = require 'ssh2'
fs = require 'fs'
_ = require 'underscore'

module.exports.Updater = class Updater
  app: null
  server: null
  conf: {}
  constructor: (server, app)->
    _.bindAll this
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
      message: data.toString()
  logMessage: (data, extended)->
    @app.emit 'serverLogMessage', @createLogMessage(data, extended)
  runUpdates: (done)->
    sshConnection = new Connection()
    self = this
    logError = @app.log.error
    logInfo = @app.log.error
    sshLocation = @getSSHLocation()
    sshConnection.on 'ready', ->
      sshConnection.exec self.app.config.get('defaultUpdateCommand'), (error, stream)->
        self.app.log.info "Connected to #{sshLocation}"
        if error
          self.app.log.error "Error connecting to #{sshLocation}, updates could not be run."
          done error
          return
        stream.on 'data', (data, extended)->
          self.logMessage.apply self, [data, extended]
        stream.on 'exit', (code, signal)->
          if code.toString() == '0'
            self.app.log.info "Terminating connection with #{sshLocation}"
            sshConnection.end()
            console.log "Emitting serverUpdateComplete::#{self.server.getHostname()}"
            self.app.emit "serverUpdateComplete::#{self.server.getHostname()}", {success: true, server: self.server}
            done()
          else
            self.app.log.info "Terminating connection with #{sshLocation}"
            self.app.log.error "Update command on #{sshLocation} failed.", arguments
            sshConnection.end()
            self.app.emit "serverUpdateComplete::#{self.server.getHostname()}", {success: false, server: self.server}
            done new Error 'Something went wrong with SSH'
    sshConnection.on 'error', (error)->
      logError "Connecting to #{sshLocation} failed."
    self.app.log.info "Connecting to #{sshLocation}"
    sshConnection.connect @conf
