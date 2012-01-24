helper = require('./helper')
alternator = helper.alternator
messages = require('../src/messages')

describe 'deletTable', ->

  it "returns an error on null table name", (done) ->
    Helper.assertInvalid(null, messages.invalidTableName(), false, done)

  it "returns an error on null table name", (done) ->
    Helper.assertInvalid('1', messages.invalidTableName(), false, done)

  it "returns an error on null table name", (done) ->
    Helper.assertInvalid((n for n in [1..259]), messages.invalidTableName(), false, done)

  it "returns an error on invalid table name", (done) ->
    Helper.assertInvalid('over9000!!!', messages.invalidPattern('tableName', 'over9000!!!', /^[a-zA-Z0-9_.-]+$/), true, done)

  describe 'persistence', ->
    beforeEach (done) -> helper.setupDatabase(done)
    afterEach -> helper.closeDatabase()

    it "returns an error if the table doesn't exist", (done) ->
      Helper.assertInvalid('unicorns', messages.tableNotFound('unicorns'), false, done)

    it "deletes the table form the system table", (done) ->
      helper.async (db) ->
        ddb = db.collection('ddb_tables')
        ddb.insert [{_id: 'unicorns', details: {blah: true, TableStatus: 'active'}}, {_id: 'vampires', details: {}}], ->
          alternator.deleteTable {TableName: 'unicorns'}, (err, response) ->
            expect(err).toBeNull();
            expect(response).toEqual({blah: true, TableStatus: 'DELETING'})
            ddb.count {}, (err, count) ->
              expect(count).toEqual(1)
              ddb.count {_id: 'unicorns'}, (err, count) ->
                expect(count).toEqual(0)
                done()

    it "deletes the data table", (done) ->
      helper.async (db) ->
        ddb = db.collection('ddb_tables')
        ddb.insert {_id: 'unicorns', details: {}}, ->
          db.collection('unicorns').insert {a: 1}, ->
            alternator.deleteTable {TableName: 'unicorns'}, (err, response) ->
              db.collection('unicorns').count {}, (err, count) ->
                expect(count).toEqual(0)
                done()


class Helper
  @assertInvalid: (name, expected, includeCount, done) ->
    helper.async ->
      alternator.deleteTable {TableName: name}, (err, response) ->
        expect(response).toBeNull()
        expect(err.__type).toEqual(expected.__type)
        expectedMessage = expected.message
        expectedMessage = '1 validation error detected: ' + expectedMessage if includeCount == true
        expect(err.message).toEqual(expectedMessage)
        done()