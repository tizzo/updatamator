flatiron = require 'flatiron'
path = require 'path'
app = flatiron.app
Winston = require 'winston'
fs = require 'fs'
ecstatic = require 'ecstatic'
plates = require 'plates'
redis = require 'fakeredis'
coffee = require 'coffee-script'


Winston.loggers.add 'default',
  console:
    level: '',
    colorize: true
app.log = Winston.log

app.RedisClient = redis.createClient()

# require('../lib/routes').attach app
module.exports = app
