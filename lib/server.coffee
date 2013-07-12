crypto = require 'crypto'
_ = require 'underscore'
moment = require 'moment'

module.exports.Server = class Server
  hostname: ''
  version: ''
  updates: []
  issue: ''
  app: {}
  redisClient: {}
  remoteUpdater: null
  packageString: false
  packageSet: null

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
    if data.packageSet
      @packageSet = data.packageSet

  save: (next = false)->
    done = (error, response) ->
      if next and error
        next error, null
      else if next and not error
        next null, true
    oldServerData = new Server {}, @app
    multi = @redisClient.multi()
    redis = @redisClient
    self = this
    oldServerData.load @hostname, (error, oldPackageString)->
      if oldPackageString != null and oldPackageString != self.getPackageString()
        redis.smembers oldPackageString, (error, hosts)->
          multi = redis.multi()
          if hosts.length == 0
            multi.del oldPackageString
            multi.del "package-set:#{oldPackageString}:release-notes"
            multi.srem 'packages', oldPackageString
          multi.srem oldPackageString, self.getHostname()
          multi.exec()
    time = Math.round new Date().getTime() / 1000
    multi.zadd ['last-reported', time, @getHostname()]
    if @getPackages().length is 0
      console.log "and away we go #{@getHostname()}"
      multi.zadd ['up-to-date', time, @getHostname()]
      multi.exec done
    else
      multi.zrem 'up-to-date', @getHostname()
      multi.set @getHostname(), @getPackageString()
      multi.sadd @getPackageString(), @getHostname()
      multi.sadd 'hosts', @getHostname()
      multi.sadd 'issues', @getIssue()
      multi.sadd 'packages', @getPackageString()
      multi.set "package-set:#{@getPackageString()}:release-notes", JSON.stringify @getPackageNotes()
      multi.exec done

  removeMonitoring: (next)->
    multi = @redisClient.multi()
    multi.zrem 'up-to-date', @getHostname()
    multi.zrem 'last-reported', @getHostname()
    multi.exec next


  load: (hostname, next)->
    @hostname = hostname
    multi = @redisClient.multi()
    @app.on "serverUpdateComplete::#{hostname}", @updateCompleteHandler
    self = this
    redis = @redisClient
    redis.get @getHostname(), (error, packageString)->
      if packageString is null
        # TODO: FIXME
        # self.app.log.error "Warning package string is null for #{hostname}. Performing cleanup."
        if self.packageSet
          cleanupPackageString = self.packageSet.packageString
          self.removeEmitters()
          self.removeUpdateInformation cleanupPackageString
          return next()
        else
          self.packageString = packageString

      redis.get "package-set:#{packageString}:release-notes", (error, updates)->
        self.updates = JSON.parse updates
        next(error, packageString)

  getPackageNotes: ->
    notes = {}
    notes[packageName] = note for packageName, note of @updates
    notes

  getHostname: -> @hostname

  getCSSName: (hostname)->
    if not hostname
      hostname = @getHostname()
    hostname.replace(/\./g, '-')

  getIssue: -> @issue

  getPackages: ->
    updates = []
    updates.push update for update, notes of @updates
    updates

  getUpToDateServers: (themable, next)->
    if arguments.length == 1
      next = arguments[0]
      themable = null
    @redisClient.zrevrange 'up-to-date', 0, -1, 'WITHSCORES', (error, results)->
      items = []
      for i, item of results
        if (i % 2) is 0
          lastUpdatedTime = results[Number(i) + 1]
          if themable
            lastUpdatedTime = moment(Number(lastUpdatedTime) * 1000).format('MMMM Do YYYY, h:mm:ss a')
          items.push { hostname: results[i], lastUpdated: lastUpdatedTime }
      next error, items

  getReportedServers: (themable, next)->
    self = this
    if arguments.length == 1
      next = arguments[0]
      themable = null
    @redisClient.zrevrange 'last-reported', 0, -1, 'WITHSCORES', (error, results)->
      items = []
      for i, item of results
        if (i % 2) is 0
          lastUpdatedTime = results[Number(i) + 1]
          if themable
            lastUpdatedTime = moment(Number(lastUpdatedTime) * 1000).format('MMMM Do YYYY, h:mm:ss a')
            hostname = results[i]
          items.push { hostname: hostname, lastUpdated: lastUpdatedTime, cssName: self.getCSSName(hostname)}
      next error, items

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

  removeUpdateInformation: (packageString = null)->
    redis = @redisClient
    if packageString is null
      packageString = @getPackageString()
    multi = redis.multi()
    multi.srem 'hosts', @getHostname()
    multi.srem packageString, @getHostname()
    multi.del @getHostname()
    log = @app.log
    hostname = @getHostname()
    hadError = []
    done = ->
      if hadError.length > 0
        log.error "Update complete for #{hostname} but removal from update list failed.", hadError
      else
        log.info "Update complete for #{hostname}, removed from update list."
    multi.exec (error, response)->
      if error
        hadError.push error
      redis.smembers packageString, (error, servers)->
        if servers.length == 0
          multi = redis.multi()
          multi.srem 'packages', packageString
          multi.del "#package-set:{packageString}:release-notes"
          multi.exec (error, response)->
            if error
              hadError.push error
            done()
        else
          done()
  updateCompleteHandler: (data)->
    @serverUpdateComplete data
  # TODO: rename this `removeListeners`
  removeEmitters: ->
    @app.removeListener "serverUpdateComplete::#{@getHostname()}", @updateCompleteHandler
  serverUpdateComplete: (data)->
    if data.success
      @removeEmitters()
      @removeUpdateInformation()
