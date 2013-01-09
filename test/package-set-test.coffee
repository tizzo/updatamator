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
  describe '#listSets()', ->
    it 'should find two package sets', ->
      packageSet.listSets (error, sets)->
        assert.equal sets.length, 2, 'Two package sets found'
  describe '#load()', ->
    it 'should load data properly', ->
      packageSet.listSets (error, sets)->
        packageSet.load sets[0], (error)->
          describe '#getServers()', ->
            it 'should have two servers in the first package set', ->
              assert.equal packageSet.getServers().length, 2, 'Two servers found in the first package set.'
            it 'should have one server in the second package set', (done) ->
              packageSet2 = new PackageSet(app)
              packageSet2.load sets[1], (error)->
                assert.equal packageSet2.getServers().length, 1, 'One server found in the second package set.'
                done()
          describe '#listPackages', ->
            it 'should list one package', (done)->
              console.log packageSet.listPackages()
          describe '#getReleaseNotes()', ->
            it 'should be a hash containing all of the release notes for each package.', (done)->
              assert.equal packageSet.getReleaseNotes()
              done()
          describe '#updateServers()', ->
            it 'should run the update command on each server', (done)->
              # TODO: run some code here
              done()
