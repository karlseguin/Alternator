middleware = require('./middleware')
alternator = require('./alternator')
connect = require('connect')

runServer = (config) ->
  alternator.initialize config.db, (err) ->
    if err?
      console.log('store initialization error: %s', err)
      process.exit(1)
    else
      server = connect()
        .use(middleware.contextParser())
        .use(middleware.bodyParser())
        .use(connect.router (app) ->
          app.post '/', (req, res, next) ->
            alternator.process(req, res)
        )
        .listen(config.server.port, config.server.host)

      console.log('Server running on http://%s:%d', config.server.host, config.server.port);


module.exports = runServer