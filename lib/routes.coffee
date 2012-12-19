coffee = require 'coffee-script'
fs = require 'fs'

module.exports.attach = (app)->
  app.router.get '/', ->
    console.log 'here'
    context = this
    app.sendResponse context, 200, app.renderPage(context)

  app.router.post '/package-updates', ->
    context = this
    data = context.req.body
    # console.log data
    console.log context.req
    JSON.parse context.req.body
    if data
      response = 201
    else
      response = 500
    context.res.writeHead response,
      'Content-Type': 'application/json'
    context.res.json 'Updates recorded'

