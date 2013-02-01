app =
  templates: {}
  mappings: {}
for template, mapping in settings.mappings
  console.log "#{template}"
  app.mappings[template] = Plates.Map()
  app.mappings[template].mappings = mapping

$(document).ready ($)->
  # Load our templates into memory for client side rendering.
  $('#templates script').each -> app.templates[$(this).attr 'id'] = $(this).text()
  $('#templates').remove()

  # Activate Foudnation accordion.
  $('#page ul.accordion').foundationAccordion()

  # Setup each package set.
  $('li.available-package-set').each ()->

    # Setup internal pacakge detail collapsible behavior.
    packageDetails = $('.release-details ul.available-packages', this).hide()
    $('.release-details h5').click (event)->
      packageDetails.slideToggle('slow')



  # TODO: get the url dynamically
  socket = io.connect('http://localhost:3005');
  socket.on 'data', (data)->
    console.log data


root = exports ? this
root.app = app
