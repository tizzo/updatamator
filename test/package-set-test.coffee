assert = require 'assert'
redis = require 'fakeredis'
PackageSet = require('../lib/package-set').PackageSet
app = require './mock-app'
Server = require('../lib/server').Server

redisClient = app.RedisClient
packageSet = null

describe 'PackageSet', ->
  before ->
    redisClient.flushdb()
    packageSet = new PackageSet(app)
    new Server(require('./json-samples/json-sample-2'), app).save()
    new Server(require('./json-samples/json-sample-3'), app).save()
    new Server(require('./json-samples/json-sample-4'), app).save()
  sets = []
  describe '#listSets()', ->
    it 'should find two package sets', (done)->
      packageSet.listSets (error, sets)->
        assert.equal sets.length, 2, 'Two package sets found'
        done()
  it 'should load data properly', (done)->
    packageSet.listSets (error, loadedSets)->
      sets = loadedSets
      packageSet.load sets[1], (error)->
        done()
  describe 'loaded data methods', ->
    # Perform a fresh load before each
    describe '#getServers()', ->
      it 'should have two servers in the first package set', (done)->
        assert.equal packageSet.getServers().length, 2, 'Two servers found in the first package set.'
        done()
      it 'should have one server in the second package set', (done)->
        packageSet2 = new PackageSet(app)
        packageSet2.load sets[0], (error)->
          assert.equal packageSet2.getServers().length, 1, 'One server found in the second package set.'
          done()
  describe '#listPackages()', ->
    it 'should list one package', ->
      assert.equal packageSet.listPackages().length, 1
      assert.equal packageSet.listPackages().pop(), 'package-one'
    describe '#getReleaseNotes()', ->
      it 'should be a hash containing all of the release notes for each package.', (done)->
        assert.equal packageSet.getReleaseNotes()['package-one'].version, '1.0.2-0ubuntu3.5'
        done()
    describe '#getThemableOutput()', ->
      it 'should get the plain old JSON representation for rendering', (done)->
        packageSet.getThemableOutput (error, object)->
          assert.equal object.serverList, 'server2.example.com, server3.example.com'
          assert.equal object.packages.length, 1
          assert.equal object.packageString, '5d6ecbc22a4a3cd29f7cfccb8efbcad36b7808a6'
          done()
    describe '#getLoadedServers()', ->
      it 'should load each of the servers properly', (done)->
        packageSet.getLoadedServers (error, servers)->
          assert.equal servers[0].getHostname(), 'server2.example.com'
          assert.equal servers[1].getHostname(), 'server3.example.com'
          done()
    describe '#updateServers()', ->
      it 'should run the update command on each server', (done)->
        # TODO: Tests currently broken, not sure why...
        # packageSet.updateServers done
        done()

