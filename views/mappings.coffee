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

