module.exports.server = class Server
  hostname: ''
  version: ''
  updates: []
  redisClient: {}
  constructor: (data, redisClient)->
    @redisClient = redisClient
    @set(data)
  set: (data)->
    @hostname = data.hostname
    @version = ''
    @updates = data.updates

  save: (next = false)->
    @redisClient.set @getHostname(), @getUpdates().join(':')
    if next
      next()

  getHostname: -> @hostname
  getUpdates: ->
    updates = []
    updates.push update for update, notes of @updates
    updates

