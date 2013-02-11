crypto = require 'crypto'

module.exports.Server = class Server
  hostname: ''
  version: ''
  updates: []
  issue: ''
  app: {}
  redisClient: {}
  remoteUpdater: null

  constructor: (data, app)->
    @app = app
    @redisClient = app.RedisClient
    @set(data)
    if @app.config.get 'testing'
      Updater = require('../test/plugins/testSSH2RemoteExecutor').Updater
    else
      console.log 'here'
      Updater = require('./plugins/ssh2RemoteExecutor').Updater
    @remoteUpdater = new Updater(this, app)

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
    @redisClient.get @getHostname(), (error, packageString)->
      @packageString = packageString
      next(error, packageString)
    # multi.sadd @getPackageString(), @getHostname()
    # multi.sadd 'hosts', @getHostname()
    # multi.sadd 'packages', @getPackageString()
    # multi.set "#{@getPackageString()}:release-notes", JSON.stringify @getPackageNotes()
    # multi.exec (error, response) ->
    #  if next and error
    #    next error, null
    #  else if next and not error
    #    next false, true

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
    packageVersions = []
    packageVersions.push "#{packageName}@#{details.version}" for packageName, details of @updates
    shasum = crypto.createHash 'sha1'
    shasum.update packageVersions.join ':'
    shasum.digest 'hex'

  removeUpdateInformation: ->
    multi = @redisClient.multi()
    multi.srem 'hosts', @getHostname()
    multi.srem @getPackageString(), @getHostname()
    # TODO: Check the total number in the package and remove the string if empty?
    # multi.srem 'packages', @getPackageString()
    # TODO: Check the total number in the servers in the string and clear the gc the release notes if empty?
    # multi.del "#{@getPackageString()}:release-notes", JSON.stringify @getPackageNotes()
    multi.exec (error, response)->
      console.log "Update run for #{@getHostname()}"
      # @runApticronScript()?

  runUpdates: ->
    console.log 'server::runUpdates()'
    @remoteUpdater.runUpdates()


