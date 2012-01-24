helper = require('./helper')
alternator = helper.alternator
messages = require('../src/messages')

describe 'listTables', ->    
  it "returns an error on null table name", (done) ->
    Helper.assertInvalid {ExclusiveStartTableName: null}, messages.invalidTableName(), done

  it "returns an error on short table name", (done) ->
    Helper.assertInvalid {ExclusiveStartTableName: '12'}, messages.invalidTableName(), done

  it "returns an error on long table name", (done) ->
    Helper.assertInvalid {ExclusiveStartTableName: (n for n in [1..256]).join('')}, messages.invalidTableName(), done

  it "returns an error in invalid limit", (done) ->
    Helper.assertInvalid {limit: 'b'}, messages.cannotSerializeStringToLong(), done

  describe 'persistence', ->
    beforeEach (done) -> helper.setupDatabase(done)
    afterEach -> helper.closeDatabase()

    it "returns an empty list", (done) ->
      helper.async ->
        Helper.assertList {}, [], null, done

    it "lists the tables", (done) ->
      helper.async (db) ->
        db.collection('ddb_tables').insert [{_id: 'tableB'}, {_id: 'tableA'}], ->
          Helper.assertList {}, ['tableA', 'tableB'], null, done

    it "limits the tables returned the tables", (done) ->
      helper.async (db) ->
        db.collection('ddb_tables').insert [{_id: 'tableB'}, {_id: 'tableA'} , {_id: 'tablec'}], ->
          Helper.assertList {Limit:2}, ['tableA', 'tableB'], 'tableB', done

    it "gets the table from the specified start", (done) ->
      helper.async (db) ->
        db.collection('ddb_tables').insert [{_id: 'tableB'}, {_id: 'tableA'} , {_id: 'tableC'}], ->
          Helper.assertList {ExclusiveStartTableName: 'tableA'}, ['tableB', 'tableC'], null, done


class Helper
  @assertInvalid: (data, expected, done) ->
    helper.async ->
      alternator.listTables data, (err, response) ->
        expect(response).toBeNull()
        expect(err.__type).toEqual(expected.__type)
        expect(err.message).toEqual(expected.message)
        done()

  @assertList: (data, expected, lastTable, done) ->
    alternator.listTables data, (err, response) ->
      expect(err).toBeNull()
      expect(response.TableNames).toEqual(expected)
      if lastTable?
        expect(response.LastEvaluatedTableName).toEqual(lastTable)
      else
        expect(response.LastEvaluatedTableName).toBeUndefined()
      done()