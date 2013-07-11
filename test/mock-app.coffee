flatiron = require 'flatiron'
path = require 'path'
app = flatiron.app
Winston = require 'winston'
fs = require 'fs'
ecstatic = require 'ecstatic'
plates = require 'plates'
redis = require 'fakeredis'
coffee = require 'coffee-script'

app.config.set 'testing', true

Winston.loggers.add 'default',
  console:
    level: '',
    colorize: true
app.log = Winston.log

app.RedisClient = redis.createClient()
app.use flatiron.plugins.http
app.start()
# require('../lib/routes').attach app
module.exports = app

# TODO: This should be an an app class that is used on tests and main process.
app.on 'runUpdate', (packageString)->
  packageSet = new PackageSet(app)
  packageSet.load packageString, (error)->
    if not error
      packageSet.updateServers (error)->
