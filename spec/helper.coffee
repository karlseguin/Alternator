alternator = require('../src/alternator')
module.exports.alternator = alternator
mongo = null

setupDatabase = (done) ->
  alternator.initialize {host: '127.0.0.1', port: 27017, database: 'alternator_test'}, (err, db) ->
    mongo = db
    db.collection('ddb_tables').drop ->
      db.collection('users').drop ->
        db.collection('ddb_tables').insert {_id: 'users', details: {KeySchema: {HashKeyElement: {AttributeName: 'id', AttributeType: 'N'}}}}, ->
          db.collection('ddb_tables').insert {_id: 'votes', details: {KeySchema: {HashKeyElement: {AttributeName: 'id', AttributeType: 'S'}, RangeKeyElement: {AttributeName: 'count', AttributeType: 'N'}}}}, ->
            done()
        

closeDatabase = ->
  mongo.close() if mongo?

async = (callback) -> 
  setTimeout ( -> callback(mongo)), 1
  
assertRequestError = (method, data, expected, includeCount, done) ->
  async ->
    alternator[method] data, (err, response) ->
      expect(response).toBeNull()
      expect(err.__type).toEqual(expected.__type)
      expectedMessage = expected.message
      expectedMessage = '1 validation error detected: ' + expectedMessage if includeCount == true
      expect(err.message).toEqual(expectedMessage)
      done()

module.exports.setupDatabase = setupDatabase
module.exports.async = async
module.exports.closeDatabase = closeDatabase
module.exports.assertRequestError = assertRequestError