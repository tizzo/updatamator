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
    $('.release-details h5', this).click (event)->
      packageDetails.slideToggle('slow')


    logs = $('.update-logs', this)
    serverLogs = $('.server-logs', logs).hide()
    $('h5.update-logs-title', this).click (event)->
      serverLogs.slideToggle('slow')
    $('input.update').click (event)->
      serverLogs.show()
    $('.server', serverLogs).each ->
      server = this
      $('h6.server-name', server).click ->
        console.log 'toggle'
        $('.log-code', server).slideToggle()

  socket = io.connect()
  # Internal cache for
  elements = {}
  socket.on 'serverLogMessage', (message)->
    if not elements[message.cssName]
      elements[message.cssName] = $(".server##{message.cssName}-logs .log-contents")
    elements[message.cssName].append Plates.bind app.templates['server-logs-message'], message, window.mappings['server-logs-message']

root = exports ? this
root.app = app
