assert = require 'assert'
Server = require('../lib/server').Server
app = require './mock-app'
redisClient = app.RedisClient

server = null

describe 'Server', ->
  before (done)->
    data = require('./json-samples/json-sample-1')
    server = new Server(data, app)
    redisClient.flushdb done
  describe '#getHostname()', ->
    it 'should report the hostname', ->
      assert.equal server.getHostname(), 'server1.example.com'
  describe '#getCSSName()', ->
    it 'should provide a css class safe representation of the hostname', ->
      assert.equal server.getCSSName(), 'server1-example-com'
  describe '#getPackages()', ->
    it 'should return the list of packages', ->
      assert.equal server.getPackages().length, 36, 'Correct number of packages found'
      assert.equal server.getPackages()[35], 'perl-modules'
      assert.equal server.getPackages()[0], 'apparmor'
  describe '#packageString()', ->
    it 'should receive the correct package string', ->
      assert.equal server.getPackageString(), '2ab54a26230793ccf6ebee3fb97da63c9d285858'
  describe '#save()', ->
    it 'should persist the server and package information to redis', (done)->
      server.save done
    it 'should retrieve the correct package list', (done)->
      redisClient.get 'server1.example.com', (error, data)->
        assert.equal 40, data.length
        done()
    it 'should find the hostname is in package list', (done)->
      redisClient.sismember server.getPackageString(), 'server1.example.com', (error, data)->
        assert.equal data, true
        done()
    it 'should find the hostname in hosts list', (done)->
      redisClient.sismember 'hosts', server.getHostname(), (error, data)->
        assert.equal data, true
        done()
    it 'should find the package string in packages list.', (done)->
      redisClient.sismember 'packages', server.getPackageString(), (error, data)->
        assert.equal data, true
        done()
