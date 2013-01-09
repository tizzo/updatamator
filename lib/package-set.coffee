module.exports.PackageSet = class PackageSet
  app: {}
  redisClient: {}
  constructor: (app)->
    @app = app
    @redisClient = app.RedisClient
  set: (data)->
    @hostname = data.hostname
    @version = ''
    @updates = data.updates
    this
  load: (packageString, next)->
    multi = @redisClient.multi()
    multi.exec (error, data)->
      console.log data
    this
