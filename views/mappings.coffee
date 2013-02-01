
mappings = {}

if module
  Plates = require 'plates'
  root = module.exports
else
  root = this

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
map.where('class').is('server-list').use('serverList')
map.where('class').is('available-packages').use('available-packages')
mappings['available-package-set'] = map

map = Plates.Map()
map.class('package-title').to('title')
map.class('version').to('version')
map.class('release-notes-detail').to('release_notes')
mappings['package-detail'] = map
