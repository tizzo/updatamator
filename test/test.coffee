assert = require 'assert'
Server = require('../lib/server').server
redis = require 'fakeredis'
redisClient = redis.createClient()

# TODO: Isn't there some way to pass variables forward in tests?
# it 'should accept data as the constructor', ->
data = require('./json-samples/json-sample-1')
server = new Server(data, redisClient)

describe 'Server', ->
  describe '#getHostname()', ->
    it 'should report the hostname', ->
      assert.equal server.getHostname(), 'localhost'
  describe '#getPackages()', ->
    it 'should return the list of packages', ->
      assert.equal server.getUpdates().length, 36, 'Correct number of packages found'
      assert.equal server.getUpdates()[35], 'perl-modules'
      assert.equal server.getUpdates()[0], 'apparmor'
  describe '#save()', ->
    server.save ->
      redisClient.get 'localhost', (err, data)->
        assert.equal 490, data.length, 'Correct package list has been retrieved'
