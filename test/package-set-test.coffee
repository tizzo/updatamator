assert = require 'assert'
redis = require 'fakeredis'
PackageSet = require('../lib/package-set').PackageSet
app = require './mock-app'
Server = require('../lib/server').Server

redisClient = app.RedisClient

# TODO: Isn't there some way to pass variables forward in tests?
# it 'should accept data as the constructor', ->
data = require('./json-samples/json-sample-1')
packageSet = new PackageSet(app)

new Server(require('./json-samples/json-sample-2'), app).save()
new Server(require('./json-samples/json-sample-3'), app).save()
new Server(require('./json-samples/json-sample-4'), app).save()

describe 'PackageSet', ->
  sets = []
  describe '#listSets()', ->
    it 'should find two package sets', ->
      packageSet.listSets (error, sets)->
        assert.equal sets.length, 2, 'Two package sets found'
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
          done()
    describe '#getLoadedServers()', ->
      it 'should load each of the servers properly', (done)->
        packageSet.getLoadedServers (error, servers)->
          assert.equal servers[0].getHostname(), 'server2.example.com'
          assert.equal servers[1].getHostname(), 'server3.example.com'
        done()
    describe '#updateServers()', ->
      it 'should run the update command on each server', (done)->
        # TODO: run some code here
        packageSet.updateServers()
        done()

