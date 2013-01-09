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
      that.servers = data[0]
      that.releaseNotes = JSON.parse(data[1])
      next error
  getServers: ->
    @servers
  getReleaseNotes: ->
    # return this.releaseNotes
  listPackages: ->
    item for item, notes of @releaseNotes
  listSets: (next) ->
    @redisClient.smembers 'packages', (error, packageSets)->
      next error, packageSets
