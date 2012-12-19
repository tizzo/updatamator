module.exports.server = class Server
  hostname: ''
  version: ''
  updates: []
  constructor: (data, app)->
    @app = app
    @hostname = data.hostname
    @version = ''
    @updates = data.updates
  set: (data)->

  save: (data)->

  getHostname: -> @hostname

