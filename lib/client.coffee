app =
  templates: {}
  mappings: {}
for template, mapping in settings.mappings
  console.log "#{template}"
  app.mappings[template] = Plates.Map()
  app.mappings[template].mappings = mapping

$(document).ready ($)->
  $('#templates script').each -> app.templates[$(this).attr 'id'] = $(this).text()
  $('#templates').remove()
  $('#page ul.accordion').foundationAccordion();

  # TODO: get the url dynamically
  socket = io.connect('http://localhost:3005');
  socket.on 'data', (data)->
    console.log data


root = exports ? this
root.app = app
