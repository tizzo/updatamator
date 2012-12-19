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

  app.router.get 'js/minified.js', ->
    if not app.clientScripts
      javascript = ''
      javascripts = [
        'clientLib/jquery-1.8.0.min'
      ]
      for name in javascripts
        javascript += fs.readFileSync app.dir + "/#{name}.js", 'utf8'
      coffeescripts = [
        'lib/client'
      ]
      for name in coffeescripts
        javascript += coffee.compile fs.readFileSync "#{app.dir}/#{name}.coffee", 'utf8'
      app.clientScripts = javascript
    app.sendResponse this, 200, app.clientScripts,
      'Content-Type': 'application/javascript'
