helper = require('./helper')
alternator = helper.alternator
messages = require('../src/messages')

describe 'createTable', ->    
  it "returns an error on null table name", (done) ->
    Helper.assertInvalid {TableName: null}, messages.invalidTableName(), false, done

  it "returns an error on short table name", (done) ->
    Helper.assertInvalid {TableName: '12'}, messages.invalidTableName(), false, done

  it "returns an error on long table name", (done) ->
    Helper.assertInvalid {TableName: (n for n in [1..256])}, messages.invalidTableName(), false, done

  it "returns an error on missing keySchema", (done) ->
    data = Helper.validData()
    delete data['KeySchema']
    Helper.assertInvalid data, messages.cannotBeNull('keySchema'), true, done

  it "returns an error on missing keySchema.hashKeyElement", (done) ->
    data = Helper.validData()
    delete data['KeySchema']['HashKeyElement']
    Helper.assertInvalid data, messages.cannotBeNull('keySchema.hashKeyElement'), true, done

  it "returns an error on missing keySchema.hashKeyElement.attributeName", (done) ->
    data = Helper.validData()
    delete data['KeySchema']['HashKeyElement']['AttributeName']
    Helper.assertInvalid data, messages.cannotBeNull('keySchema.hashKeyElement.attributeName'), true, done

  it "returns an error on missing keySchema.hashKeyElement.attributeType", (done) ->
    data = Helper.validData()
    delete data['KeySchema']['HashKeyElement']['AttributeType']
    Helper.assertInvalid data, messages.cannotBeNull('keySchema.hashKeyElement.attributeType'), true, done

  it "returns an error on invalid keySchema.hashKeyElement.attributeType", (done) ->
    data = Helper.validData()
    data['KeySchema']['HashKeyElement']['AttributeType'] = 'X'
    Helper.assertInvalid data, messages.invalidValueForEnum('keySchema.hashKeyElement.attributeType', 'X', ['N', 'S']), true, done

  it "returns an error on missing keySchema.rangeKeyElement.attributeName", (done) ->
    data = Helper.validData()
    delete data['KeySchema']['RangeKeyElement']['AttributeName']
    Helper.assertInvalid data, messages.cannotBeNull('keySchema.rangeKeyElement.attributeName'), true, done

  it "returns an error on missing keySchema.rangeKeyElement.attributeType", (done) ->
    data = Helper.validData()
    delete data['KeySchema']['RangeKeyElement']['AttributeType']
    Helper.assertInvalid data, messages.cannotBeNull('keySchema.rangeKeyElement.attributeType'), true, done

  it "returns an error on invalid keySchema.rangeKeyElement.attributeType", (done) ->
    data = Helper.validData()
    data['KeySchema']['RangeKeyElement']['AttributeType'] = 'Y'
    Helper.assertInvalid data, messages.invalidValueForEnum('keySchema.rangeKeyElement.attributeType', 'Y', ['N', 'S']), true, done

  it "returns an error on missing provisionedThroughput", (done) ->
    data = Helper.validData()
    delete data['ProvisionedThroughput']
    Helper.assertInvalid data, messages.cannotBeNull('provisionedThroughput'), true, done

  it "returns an error on missing provisionedThroughput.writeCapacityUnits", (done) ->
    data = Helper.validData()
    delete data['ProvisionedThroughput']['WriteCapacityUnits']
    Helper.assertInvalid data, messages.cannotBeNull('provisionedThroughput.writeCapacityUnits'), true, done

  it "returns an error on missing provisionedThroughput.readCapacityUnits", (done) ->
    data = Helper.validData()
    delete data['ProvisionedThroughput']['ReadCapacityUnits']
    Helper.assertInvalid data, messages.cannotBeNull('provisionedThroughput.readCapacityUnits'), true, done

  it "merges multiple messages together", (done) ->
    data = Helper.validData()
    delete data['ProvisionedThroughput']['ReadCapacityUnits']
    data['KeySchema']['RangeKeyElement']['AttributeType'] = 'Y'
    Helper.assertInvalid data, (error) ->
      expect(error.__type).toEqual('com.amazon.coral.validate#ValidationException')
      expect(/^2 validation errors detected:/.test(error.message)).toEqual(true)
      errors = error.message[29..].split(';')
      expect(errors.length).toEqual(2)
      expect(errors[0]).toEqual(' ' + messages.invalidValueForEnum('keySchema.rangeKeyElement.attributeType', 'Y', ['N', 'S']).message)
      expect(errors[1]).toEqual(' ' + messages.cannotBeNull('provisionedThroughput.readCapacityUnits').message)
      done()

  it "returns a failure on invalid serialization of readCapacityUnits", (done) ->
    data = Helper.validData()
    delete data['KeySchema']
    data['ProvisionedThroughput']['ReadCapacityUnits'] = 'b'
    Helper.assertInvalid data, messages.cannotSerializeStringToLong(), false, done

  it "returns a failure on invalid serialization of writeCapacityUnits", (done) ->
    data = Helper.validData()
    delete data['KeySchema']
    data['ProvisionedThroughput']['WriteCapacityUnits'] = 'b'
    Helper.assertInvalid data, messages.cannotSerializeStringToLong(), false, done

  describe 'persistence', ->
    beforeEach (done) -> helper.setupDatabase(done)
    afterEach -> helper.closeDatabase()

    it "saves the table information", (done) ->
      helper.async (db) ->
        alternator.createTable Helper.validData(), (err, response) ->
          expect(err).toBeNull()
          expect(response.TableDescription.TableStatus).toEqual('CREATING')
          db.collection('ddb_tables').count {_id: 'duncan'}, (err, count) ->
            expect(count).toEqual(1)
            done()

    it "returns an error on duplicate tables", (done) ->
      helper.async (db) ->
        alternator.createTable Helper.validData(), (err, response) ->
          alternator.createTable Helper.validData(), (err, response) ->
            expect(err).toEqual(messages.duplicateTableName('duncan'))
            done()

class Helper
  @validData: ->
    TableName: 'duncan'
    KeySchema:
      HashKeyElement:
        AttributeName: 'id'
        AttributeType: 'N'
      RangeKeyElement:
        AttributeName: 'time'
        AttributeType: 'S'
    ProvisionedThroughput:
      WriteCapacityUnits: 5
      ReadCapacityUnits: 5

  @assertInvalid: (data, expected, includeCount, done) ->
    helper.async ->
      alternator.createTable data, (err, response) ->
        expect(response).toBeNull()
        return expected(err) if typeof(done) == 'undefined'
        expect(err.__type).toEqual(expected.__type)
        expectedMessage = expected.message
        expectedMessage = '1 validation error detected: ' + expectedMessage if includeCount == true
        expect(err.message).toEqual(expectedMessage)
        done()