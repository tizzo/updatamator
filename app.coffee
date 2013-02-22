flatiron = require 'flatiron'
path = require 'path'
app = flatiron.app
Winston = require 'winston'
fs = require 'fs'
ecstatic = require 'ecstatic'
plates = require 'plates'
redis = require 'redis'
coffee = require 'coffee-script'
PackageSet = require('./lib/package-set').PackageSet
Server = require('./lib/server').Server

# Setup public webserver on separate port.
union = require 'union'
director = require 'director'

app.publicRouter = new director.http.Router()
server = union.createServer
  buffer: true
  before: [
    (req, res)->
      found = app.publicRouter.dispatch req, res
      if not found
        res.writeHead 404
        res.end 'Page not found'
  ]

app.config.file
  file: path.join __dirname, 'config', 'config.json'

app.use flatiron.plugins.http

Winston.loggers.add 'default',
  console:
    level: '',
    colorize: true
app.log = Winston.log

if app.config.get 'testing'
  console.log 'Booting into testing mode.'
  redis = require 'fakeredis'

require('./lib/routes').attach app

app.RedisClient = redis.createClient(app.config.get('redisPort'), app.config.get('redisHost'))

# TODO: We probably want to change this to ensure we cannot ever write to
# the wrong database because we do not wait to see that this is successful.
# fakeredis does not support `select`
if not app.config.get 'testing'
  app.RedisClient.select app.config.get('redisDatabase')

# Load our templates
app.templates = {}
for name in fs.readdirSync __dirname + '/views/templates'
  app.templates[name.substr(0, name.length - 5)] = fs.readFileSync(__dirname + "/views/templates/#{name}", 'utf8')

# Set the app's dir for other modules to include
app.dir = __dirname

# Load our mappings
app.mappings = require('./views/mappings').mappings

app.renderTemplate = (name, data = {})->
  return plates.bind app.templates[name], data, app.mappings[name]

app.renderPage = (context, data)->
  data['templates'] = app.renderTemplates(app.templates)
  data['javascript-settings'] = 'var settings =' + JSON.stringify(settings) + ';'
  return @renderTemplate 'index', data

app.sendResponse = (context, code, html, headers = {'Content-Type': 'text/html'})->
  context.res.writeHead code, headers
  context.res.end html


settings =
  mappings: {}

settings.mappings[name] = mapping.mappings for name, mapping of app.mappings

# Serve css from our static directory
app.http.before = [
  ecstatic __dirname + '/css', { autoIndex: false}
  (request, response, next)->
    response.settings = {}
    next request, response
]

app.renderTemplates = (templates)->
  string = ''
  index = templates['index']
  delete templates['index']
  items = for key, value of templates
    item =
      name: key
      template: value
  output = '<script id="template" type="text/x-plates-tmpl"></script>'
  output = plates.bind(output, items, app.mappings['template'])
  templates['index'] = index
  return output

# TODO: This is the only section with business logic in this file. PLZ FIX
app.on 'runUpdate', (packageString)->
  packageSet = new PackageSet(app)
  packageSet.load packageString, (error)->
    if not error
      packageSet.updateServers (error)->
        if error
          app.log.error "Package set update failed."
    else
      app.log.error "Loading package string #{packageString} failed."

# TODO: This is the only section with business logic in this file. PLZ FIX
app.on 'removeMonitoring', (hostname)->
  server = new Server {}, app
  server.load hostname, (error)->
    if error
      app.log.error 'Loading server to remove monitoring encountered an error.', error
    else
      server.removeMonitoring (error)->
        if not error
          app.emit 'monitoringRemoved', server


app.start app.config.get 'port'
app.log.log 'info', "Application listening on port #{app.config.get 'port'}"
app.log.log 'info', "Application publicly listening for server updates on #{app.config.get 'publicPort'}"
server.listen app.config.get 'publicPort'
require('./lib/socket').attach app
