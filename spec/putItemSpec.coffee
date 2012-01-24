helper = require('./helper')
alternator = helper.alternator
messages = require('../src/messages')

describe 'putItem', ->

  beforeEach (done) -> 
    @data = 
      TableName: 'users'
      Item:
        id: {'N':1}
        name: {'S': 'Duncan'}

    @rangeData =
      TableName: 'votes'
      Item:
        id: {'S':'leto'}
        count: {'N': 4}
    helper.setupDatabase(done)
  
  afterEach -> helper.closeDatabase()

  it "returns an error on null table name", (done) ->
    @data.TableName = null
    helper.assertRequestError 'putItem', @data, messages.invalidTableName(), false, done

  it "returns an error on short table name", (done) ->
    @data.TableName = 'b'
    helper.assertRequestError 'putItem', @data, messages.invalidTableName(), false, done

  it "returns an error on long table name", (done) ->
    @data.TableName = (n for n in [1..256]).join('')
    helper.assertRequestError 'putItem', @data, messages.invalidTableName(), false, done

  it "returns an error if the table doesn't exist", (done) ->
    data.TableName = 'invalid'
    helper.assertRequestError 'putItem', @data, messages.resourceNotFound(), false, done

  it "returns an error on missing Item", (done) ->
    delete @data.Item
    helper.assertRequestError 'putItem', @data, messages.cannotBeNull('item'), true, done

  it "returns an error on invalid return value", (done) ->
    @data.ReturnValue = 'INVALID'
    helper.assertRequestError 'putItem', @data, messages.invalidReturnValue(), false, done

  it "returns an error on missing key", (done) ->
    delete @data.Item.id
    helper.assertRequestError 'putItem', @data, messages.missingKey(), false, done

  it "returns an error on string key for integer", (done) ->
    @data.Item.id = {'S':'oops'}
    helper.assertRequestError 'putItem', @data, messages.invalidKeyType('N', 'S'), false, done

  it "returns an error on missing range key", (done) ->
    data.TableName = 'votes'
    helper.assertRequestError 'putItem', @data, messages.missingKey(), false, done

  it "returns an error on integer for for string", (done) ->
    data.TableName = 'votes'
    data.Item.count = {'S': '123'}
    helper.assertRequestError 'putItem', @data,  messages.invalidKeyType('S', 'N'), false, done
  
  it "saves an new item", (done) ->
    helper.async (db) ->
      alternator.putItem @data, (err, response) ->
        expect(err).toBeNull()
        expect(response).toBeUndefined(response)
        db.collection('users').count {_id: 1, name: 'Duncan'}, (err, count) ->
          expect(count).toEqual(1)
          done()

  it "saves an new item with a range key", (done) ->
    helper.async (db) ->
      alternator.putItem @rangeData, (err, response) ->
        expect(err).toBeNull()
        expect(response).toBeUndefined(response)
        done()

  it "returns the undefined old value if it doesn't exist", (done) ->
    @data.ReturnValue = 'ALL_OLD'
    helper.async (db) ->
      alternator.putItem @data, (err, response) ->
        expect(err).toBeNull()
        expect(response).toBeUndefined(response)
        done()
        
  it "returns the previous old value", (done) ->
    @data.ReturnValue = 'ALL_OLD'
    helper.async (db) ->
      db.collection('users').insert {_id: 1, name: 'test'}, ->
        alternator.putItem @data, (err, response) ->
          expect(err).toBeNull()
          expect(response).toEqual({id: 1, name: 'test'})
          done()

  it "returns the previous old value for range key", (done) ->
    @rangeData.ReturnValue = 'ALL_OLD'
    helper.async (db) ->
      db.collection('votes').insert {_id: {id: 'leto', count: 4}, dynanodb_api_is_consistent: 'false', funLevel: 1}, ->
        alternator.putItem @rangeData, (err, response) ->
          expect(err).toBeNull()
          expect(response).toEqual({id: 'leto', count:4, dynanodb_api_is_consistent: 'false', funLevel: 1})
          done()
