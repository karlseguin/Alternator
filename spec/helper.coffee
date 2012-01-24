alternator = require('../src/alternator')
module.exports.alternator = alternator
mongo = null

module.exports.setupDatabase = (done) ->
  alternator.initialize {host: '127.0.0.1', port: 27017, database: 'alternator_test'}, (err, db) ->
    mongo = db
    db.collection('ddb_tables').drop ->
      db.collection('users').drop ->
        done()

module.exports.closeDatabase = ->
  mongo.close() if mongo?

module.exports.async = (callback) ->
  setTimeout ( -> callback(mongo)), 1