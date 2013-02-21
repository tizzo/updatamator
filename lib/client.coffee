app =
  templates: {}
  mappings: {}
for template, mapping in settings.mappings
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
    $('input.update', this).click (event)->
      packageString = $(this).attr('data-package-string')
      $(this).remove()
      socket.emit 'runUpdate', packageString
      serverLogs.show()
    $('.server', serverLogs).each ->
      server = this
      $('h6.server-name', server).click ->
        console.log 'toggle'
        $('.log-code', server).slideToggle()

  socket = io.connect()
  # Internal cache for server log containers so that we do
  # not query for them repeatedly as logs are streaming in.
  elements = {}
  socket.on 'serverLogMessage', (message)->
    if not elements[message.cssName]
      elements[message.cssName] = $(".server##{message.cssName}-logs .log-contents")
    elements[message.cssName].append(Plates.bind app.templates['server-logs-message'], message, window.mappings['server-logs-message'])
      # Scroll to the very bottom every time a message comes in.
      # TODO: It would be nice to do this dynamically but the async nature here means we often
      # under report the current height as we try to update.
      .scrollTop(9999999999)

root = exports ? this
root.app = app
