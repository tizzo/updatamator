fs = require 'fs'
Server = require('./server').Server

module.exports.attach = (app)->
  app.router.get '/', ->
    context = this
    content = app.renderTemplate 'available-packages', 'available-packages': app.renderTemplate 'available-package'
    data =
      content: content
    app.sendResponse context, 200, app.renderPage context, data

  app.router.post '/package-updates', ->
    context = this
    data = context.req.body
    if data.hostname and data.updates
      response = 201
      message = 'Updates recorded'
      server = new Server(data, app)
      server.save()
      app.log.info "Update information received from #{server.getHostname()}"
    else
      response = 500
      message = 'Message parsing failed'
    context.res.writeHead response,
      'Content-Type': 'application/json'
    context.res.json message

