fs = require 'fs'
coffee = require 'coffee-script'
Server = require('./server').Server
PackageSet = require('../lib/package-set').PackageSet
async = require 'async'
UglifyJS = require 'uglify-js'

module.exports.attach = (app)->
  app.router.get '/', ->
    context = this
    packageSet = new PackageSet(app)
    packageSet.listSets (error, sets)->
      loadPackageSet = (packageString, next)->
        item = new PackageSet(app)
        item.load packageString, (error)->
          if error
            return next error
          item.getThemableOutput (error, output)->
            output.packageSet = item
            next error, output
      async.map sets, loadPackageSet, (error, packageSets)->
        if error
          app.log.error 'Error loading packages for display', error
          return
        if packageSets.length > 0
          for i, packageSet of packageSets
            packageSets[i]['available-packages'] = app.renderTemplate 'package-detail', packageSet.packages
            servers = packageSet.packageSet.getServers()
            # TODO: this server.replace is duplicated from Server::getCSSName(), perhaps we should us that code somehow?
            servers = ({'server-name': server, 'css-name': "#{server.replace(/\./g, '-')}-logs"} for server in servers)
            packageSets[i]['server-logs'] = app.renderTemplate 'server-logs', servers
          availablePackageSets = app.renderTemplate 'available-package-set', packageSets
          availableUpdates = app.renderTemplate 'available-package-sets', 'available-package-sets': availablePackageSets
        else
          availableUpdates = app.renderTemplate 'all-servers-up-to-date'
        new Server({}, app).getReportedServers true, (error, servers)->
          if servers.length > 0
            checkedInRows = app.renderTemplate 'checked-in-row', servers
            checkedInMarkup = app.renderTemplate('checked-in', { 'checked-in-body': checkedInRows })
          else
            checkedInMarkup = app.renderTemplate 'no-servers-reported'
          data =
            'available-updates': availableUpdates
            'checked-in': checkedInMarkup
          app.sendResponse context, 200, app.renderPage context, data

  handleUpdatePost = ->
    context = this
    data = context.req.body
    if data.secret == app.config.get 'secret'
      if data.hostname and data.updates
        response = 201
        message = 'Updates recorded'
        server = new Server(data, app)
        server.save()
        app.log.info "Update information received from #{server.getHostname()}"
      else
        app.log.error "Bad data received", data
        response = 500
        message = 'Message parsing failed'
    else
      response = 403
      message = 'Access denied, bad secret'
      if data.hostname
        app.log.error "Bad secret submitted by server reporting to be `#{data.hostname}`"
      else
        app.log.error "Bad secret reported."
    context.res.writeHead response,
      'Content-Type': 'application/json'
    context.res.json message

  app.router.post '/package-updates', handleUpdatePost
  app.publicRouter.post '/package-updates', handleUpdatePost


  # Serve our client side javascript.
  app.router.get 'js/minified.js', ->
    if not app.clientScripts
      javascript = ''
      javascripts = [
        'clientLib/jquery-1.8.0.min'
        'clientLib/plates'
        'css/javascripts/foundation/jquery.foundation.accordion'
      ]
      for name in javascripts
        javascript += fs.readFileSync app.dir + "/#{name}.js", 'utf8'
      coffeescripts = [
        'lib/client'
        'views/mappings'
      ]
      for name in coffeescripts
        javascript += coffee.compile fs.readFileSync "#{app.dir}/#{name}.coffee", 'utf8'
      app.clientScripts = javascript
      # Javascript is now a string concatenating all included javascript.
      # Time to mangle and minify it using uglify.js
      if app.config.get 'minifyjs'
        toplevel = UglifyJS.parse javascript
        toplevel.figure_out_scope()
        compressor = UglifyJS.Compressor()
        compressed_ast = toplevel.transform compressor
        compressed_ast.figure_out_scope()
        compressed_ast.compute_char_frequency()
        compressed_ast.mangle_names()
        stream = UglifyJS.OutputStream()
        compressed_ast.print(stream)
        javascript = stream.toString()
        app.clientScripts = javascript
    app.sendResponse this, 200, app.clientScripts,
      'Content-Type': 'application/javascript'
