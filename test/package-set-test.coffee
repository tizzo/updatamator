assert = require 'assert'
redis = require 'fakeredis'
redisClient = redis.createClient()
PackageSet = require('../lib/package-set').PackageSet
app = require './mock-app'

# TODO: Isn't there some way to pass variables forward in tests?
# it 'should accept data as the constructor', ->
data = require('./json-samples/json-sample-1')
packageSet = new PackageSet(app)

describe 'PackageSet', ->
  describe '#getHostname()', ->
    it 'should load data from the package string', ->
      # assert.equal server.getHostname(), 'server1.example.com'
