# TODO: get the url dynamically
socket = io.connect('http://localhost:3005');
socket.on 'data', (data)->
  console.log data
app =
  templates: {}
$(document).ready ($)->
  $('#templates script').each -> app.templates[$(this).attr 'id'] = $(this).text()
  $('#templates').remove()
  $('#page ul').foundationAccordion();
