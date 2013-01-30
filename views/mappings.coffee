Plates = require 'plates'

mappings = {}
module.exports = mappings

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
map.where('class').is('server-list').use('serverList')
map.where('class').is('available-packages').use('available-packages')
mappings['available-package-set'] = map

map = Plates.Map()
map.where('class').is('title').use('title')
map.where('class').is('version-number').use('version')
map.where('class').is('release-notes').use('release_notes')
mappings['package-details'] = map
