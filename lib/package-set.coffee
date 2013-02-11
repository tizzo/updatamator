async = require 'async'
Server = require('./server').Server

module.exports.PackageSet = class PackageSet
  app: {}
  redisClient: {}
  servers: []
  packageString: ''
  releaseNotes: {}
  constructor: (app)->
    @app = app
    @redisClient = app.RedisClient
  set: (data)->
    @hostname = data.hostname
    @version = ''
    @updates = data.updates
    this
  load: (packageString, next)->
    @servers = []
    @packageString = packageString
    multi = @redisClient.multi()
    multi.smembers packageString
    multi.get "#{@packageString}:release-notes"
    that = this
    multi.exec (error, data)->
      if error
        next error
      else
        that.servers = data[0]
        that.releaseNotes = JSON.parse(data[1])
        next null, that
  getServers: ->
    @servers
  getLoadedServers: (done)->
    app = @app
    loadServer = (hostname, next)->
      server = new Server({}, app)
      server.load hostname, (error)->
        next error, server
    async.map @getServers(), loadServer, (error, servers)->
      done error, servers
  getReleaseNotes: ->
    @releaseNotes
  listPackages: ->
    item for item, notes of @releaseNotes
  # TODO: Move this elsewhere.
  listSets: (next) ->
    @redisClient.smembers 'packages', (error, packageSets)->
      next error, packageSets
  # Renders a plain old javascript object for rendering
  getThemableOutput: (next)->
    packages = []
    for title, item of @getReleaseNotes()
      item.title = title
      packages.push item
    json =
      packageString: @packageString
      serverList: @getServers().join ', '
      packages: packages
    next null, json
  updateServers: (finished)->
    app = @app
    packageString = @packageString
    @getLoadedServers (error, servers)->
      update = (server, done)-> server.runUpdates done
      async.forEach servers, update, (error)->
        finished()
