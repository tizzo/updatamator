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

app.on 'runUpdate', (packageString)->
  packageSet = new PackageSet(app)
  packageSet.load packageString, (error)->
    if not error
      packageSet.updateServers()

app.start app.config.get 'port'
app.log.log 'info', "Application listening on port #{app.config.get 'port'}"
require('./lib/socket').attach app
