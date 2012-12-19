flatiron = require 'flatiron'
path = require 'path'
app = flatiron.app
Winston = require 'winston'
fs = require 'fs'
ecstatic = require 'ecstatic'
plates = require 'plates'

app.config.file
  file: path.join __dirname, 'config', 'config.json'

app.use flatiron.plugins.http

Winston.loggers.add 'default',
  console:
    level: '',
    colorize: 'true'
app.log = Winston.log

require('./lib/routes').attach app


# Load our templates
app.templates = {}
for name in fs.readdirSync __dirname + '/views/templates'
  app.templates[name.substr(0, name.length - 5)] = fs.readFileSync(__dirname + "/views/templates/#{name}", 'utf8')

# Set the app's dir for other modules to include
app.dir = __dirname

# Load our mappings
app.mappings = require './views/mappings'

app.renderTemplate = (name, data = {})->
  return plates.bind app.templates[name], data, app.mappings[name]

app.renderPage = ()->
  return @renderTemplate 'index'

app.sendResponse = (context, code, html, headers = {'Content-Type': 'text/html'})->
  context.res.writeHead code, headers
  context.res.end html

# Serve css from our static directory
app.http.before = [
  ecstatic __dirname + '/css', { autoIndex: false}
  (request, response)->
    response.settings = {}
]

# Serve our client side javascript.
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

app.start app.config.get 'port'
app.log.log 'info', "Application listening on port #{app.config.get 'port'}"
require('./lib/socket').attach app
