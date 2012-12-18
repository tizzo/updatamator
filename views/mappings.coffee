Plates = require 'plates'

mappings = {}
module.exports = mappings

map = Plates.Map()
map.where('class').is('project-option').use('title')
map.where('class').is('project-option').use('id').as('value');
mappings['option'] = map
