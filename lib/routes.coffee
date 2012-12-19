coffee = require 'coffee-script'
fs = require 'fs'

module.exports.attach = (app)->
  app.router.get '/', ->
    context = this
    app.sendResponse context, 200, app.renderPage(context)

  app.router.post '/package-updates', ->
    context = this
    data = context.req.body
    if data.hostname and data.updates
      response = 201
      message = 'Updates recorded'
    else
      response = 500
      message = 'Message parsing failed'
    context.res.writeHead response,
      'Content-Type': 'application/json'
    context.res.json message

