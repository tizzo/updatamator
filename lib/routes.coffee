
module.exports.attach = (app)->
  app.router.get '/', ->
    this.res.json({ 'hello': 'world' })
