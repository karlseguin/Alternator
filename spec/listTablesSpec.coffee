helper = require('./helper')
alternator = helper.alternator
messages = require('../src/messages')

describe 'listTables', ->    
  it "returns an error on null table name", (done) ->
    helper.assertRequestError 'listTables', {ExclusiveStartTableName: null}, messages.invalidTableName(), false, done

  it "returns an error on short table name", (done) ->
    helper.assertRequestError 'listTables', {ExclusiveStartTableName: '12'}, messages.invalidTableName(), false, done

  it "returns an error on long table name", (done) ->
    helper.assertRequestError 'listTables', {ExclusiveStartTableName: (n for n in [1..256]).join('')}, messages.invalidTableName(), false, done

  it "returns an error in invalid limit", (done) ->
    helper.assertRequestError 'listTables', {limit: 'b'}, messages.cannotSerializeStringToLong(), false, done

  describe 'persistence', ->
    beforeEach (done) -> helper.setupDatabase(done)
    afterEach -> helper.closeDatabase()

    it "returns an empty list", (done) ->
      helper.async (db) ->
        db.collection('ddb_tables').remove {}, ->
          Helper.assertList {}, [], null, done

    it "lists the tables", (done) ->
      helper.async (db) ->
        Helper.assertList {}, ['users', 'votes'], null, done

    it "limits the tables returned the tables", (done) ->
      helper.async (db) ->
        Helper.assertList {Limit:1}, ['users'], 'users', done

    it "gets the table from the specified start", (done) ->
      helper.async (db) ->
        Helper.assertList {ExclusiveStartTableName: 'users'}, ['votes'], null, done


class Helper
  @assertList: (data, expected, lastTable, done) ->
    alternator.listTables data, (err, response) ->
      expect(err).toBeNull()
      expect(response.TableNames).toEqual(expected)
      if lastTable?
        expect(response.LastEvaluatedTableName).toEqual(lastTable)
      else
        expect(response.LastEvaluatedTableName).toBeUndefined()
      done()