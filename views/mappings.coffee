# This file is used on both client and server.
mappings = {}

if (typeof exports == 'object' and exports)
  Plates = require 'plates'
  root = module.exports
else
  root = this
  Plates = this.Plates

root.mappings = mappings

map = Plates.Map()
map.where('class').is('project-option').use('title')
map.where('class').is('project-option').use('id').as('value');
mappings['option'] = map

map = Plates.Map()
mappings['index'] = map

map = Plates.Map()
map.where('type').is('text/x-plates-tmpl').use('template')
map.where('id').is('template').use('name').as('id')
mappings['template'] = map

map = Plates.Map()
map.where('class').is('update-button update medium button right').use('packageString').as('data-package-string')
map.where('class').is('server-list').use('serverList')
map.where('class').is('available-packages').use('available-packages')
map.class('server-logs').to('server-logs')
map.class('count-value').to('packageCount')
mappings['available-package-set'] = map

map = Plates.Map()
map.class('package-title').to('title')
map.class('version').to('version')
map.class('release-notes-detail').to('release_notes')
mappings['package-detail'] = map

map = Plates.Map()
map.class('server-name').to('server-name')
map.class('server').use('css-name').as('id')
mappings['server-logs'] = map

map = Plates.Map()
map.class('message').use('message')
map.class('stdout').use('stream').as('class')
mappings['server-logs-message'] = map
