module.exports.Server = class Server
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
    multi = @redisClient.multi()
    multi.set @getHostname(), @getPackageString()
    multi.sadd @getPackageString(), @getHostname()
    multi.sadd 'hosts', @getHostname()
    multi.sadd 'packages', @getPackageString()
    multi.set "#{@getPackageString()}:release-notes", JSON.stringify @getPackageNotes()
    multi.exec (error, response) ->
      if next and error
        next error, null
      else if next and not error
        next false, true

  getPackageNotes: ->
    notes = {}
    notes[packageName] = note for packageName, note of @updates
    notes

  getHostname: -> @hostname

  getPackages: ->
    updates = []
    updates.push update for update, notes of @updates
    updates

  getPackageString: ->
    packageVersions = []
    packageVersions.push "#{packageName}@#{details.version}" for packageName, details of @updates
    packageVersions.join(':')

  setUpdateCommand: (command)->
    @updateCommand = command
