crypto = require 'crypto'
_ = require 'underscore'

module.exports.Server = class Server
  hostname: ''
  version: ''
  updates: []
  issue: ''
  app: {}
  redisClient: {}
  remoteUpdater: null
  packageString: false

  constructor: (data, app)->
    _.bindAll this
    @app = app
    @redisClient = app.RedisClient
    @set(data)
    self = this
        
  set: (data)->
    if data.hostname
      @hostname = data.hostname
    if data.version
      @version = ''
    if data.updates
      @updates = data.updates
    if data.issue
      @issue = data.issue

  save: (next = false)->
    multi = @redisClient.multi()
    multi.set @getHostname(), @getPackageString()
    multi.sadd @getPackageString(), @getHostname()
    multi.sadd 'hosts', @getHostname()
    multi.sadd 'issues', @getIssue()
    multi.sadd 'packages', @getPackageString()
    multi.set "#{@getPackageString()}:release-notes", JSON.stringify @getPackageNotes()
    multi.exec (error, response) ->
      if next and error
        next error, null
      else if next and not error
        next null, true

  load: (hostname, next)->
    @hostname = hostname
    multi = @redisClient.multi()
    @app.on "serverUpdateComplete:#{hostname}", @updateCompleteHandler
    self = this
    redis = @redisClient
    redis.get @getHostname(), (error, packageString)->
      # TODO: We may have a bug here...
      console.log "I believe the packagestring is: #{packageString}"
      redis.get "#{packageString}:release-notes", (error, updates)->
        self.updates = JSON.parse updates
        console.log "This is the packagestring: " + self.getPackageString()
        next(error, packageString)

  getPackageNotes: ->
    notes = {}
    notes[packageName] = note for packageName, note of @updates
    notes

  getHostname: -> @hostname

  getCSSName: ->
    @getHostname().replace(/\./g, '-')

  getIssue: -> @issue

  getPackages: ->
    updates = []
    updates.push update for update, notes of @updates
    updates

  getPackageString: ->
    if not @packageString
      packageVersions = []
      packageVersions.push "#{packageName}@#{details.version}" for packageName, details of @updates
      shasum = crypto.createHash 'sha1'
      shasum.update packageVersions.join ':'
      @packageString = shasum.digest 'hex'
    @packageString

  runUpdates: (done)->
    if @app.config.get 'testing'
      Updater = require('../test/plugins/testSSH2RemoteExecutor').Updater
    else
      Updater = require('./plugins/ssh2RemoteExecutor').Updater
    @remoteUpdater = new Updater(this, @app)
    @remoteUpdater.runUpdates done

  removeUpdateInformation: ->
    redis = @redisClient
    packageString = @getPackageString()
    multi = redis.multi()
    multi.srem 'hosts', @getHostname()
    multi.srem packageString, @getHostname()
    log = @app.log
    hostname = @getHostname()
    hadError = []
    done = ->
      if hadError.length > 0
        log.error "Update complete for #{hostname} but remove from update list failed.", hadError
      else
        log.info "Update complete for #{hostname}, removing from update list."
    multi.exec (error, response)->
      if error
        hadError.push error
      # Check to
      redis.smembers packageString, (error, servers)->
        if servers.length == 0
          multi = redis.multi()
          multi.srem 'packages', packageString
          multi.del "#{packageString}:release-notes"
          multi.exec (error, response)->
            if error
              hadError.push error
            done()
        else
          done()
  updateCompleteHandler: (data)->
    @serverUpdateComplete data
  removeEmitters: ->
    @app.removeListener "serverUpdateComplete:#{@getHostname()}", @updateCompleteHandler
  serverUpdateComplete: (data)->
    if data.success
      @removeEmitters()
      @removeUpdateInformation data
