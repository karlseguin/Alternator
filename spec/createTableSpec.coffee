helper = require('./helper')
alternator = helper.alternator
messages = require('../src/messages')

describe 'createTable', ->    
  beforeEach (done) ->
    @data = 
      TableName: 'users'
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
    done()
    
  it "returns an error on null table name", (done) ->
    helper.assertRequestError 'createTable', {TableName: null}, messages.invalidTableName(), false, done

  it "returns an error on short table name", (done) ->
    helper.assertRequestError 'createTable', {TableName: '12'}, messages.invalidTableName(), false, done

  it "returns an error on long table name", (done) ->
    helper.assertRequestError 'createTable', {TableName: (n for n in [1..256]).join('')}, messages.invalidTableName(), false, done

  it "returns an invalid table name", (done) ->
    @data['TableName'] = 'a b *'
    helper.assertRequestError 'createTable', @data, messages.invalidPattern('tableName', 'a b *', /^[a-zA-Z0-9_.-]+$/), true, done

  it "returns an error on missing keySchema", (done) ->
    delete @data['KeySchema']
    helper.assertRequestError 'createTable', @data, messages.cannotBeNull('keySchema'), true, done

  it "returns an error on missing keySchema.hashKeyElement", (done) ->
    delete @data['KeySchema']['HashKeyElement']
    helper.assertRequestError 'createTable', @data, messages.cannotBeNull('keySchema.hashKeyElement'), true, done

  it "returns an error on missing keySchema.hashKeyElement.attributeName", (done) ->
    delete @data['KeySchema']['HashKeyElement']['AttributeName']
    helper.assertRequestError 'createTable', @data, messages.cannotBeNull('keySchema.hashKeyElement.attributeName'), true, done

  it "returns an error on missing keySchema.hashKeyElement.attributeType", (done) ->
    delete @data['KeySchema']['HashKeyElement']['AttributeType']
    helper.assertRequestError 'createTable', @data, messages.cannotBeNull('keySchema.hashKeyElement.attributeType'), true, done

  it "returns an error on invalid keySchema.hashKeyElement.attributeType", (done) ->
    @data['KeySchema']['HashKeyElement']['AttributeType'] = 'X'
    helper.assertRequestError 'createTable', @data, messages.invalidValueForEnum('keySchema.hashKeyElement.attributeType', 'X', ['N', 'S']), true, done

  it "returns an error on missing keySchema.rangeKeyElement.attributeName", (done) ->
    delete @data['KeySchema']['RangeKeyElement']['AttributeName']
    helper.assertRequestError 'createTable', @data, messages.cannotBeNull('keySchema.rangeKeyElement.attributeName'), true, done

  it "returns an error on missing keySchema.rangeKeyElement.attributeType", (done) ->
    delete @data['KeySchema']['RangeKeyElement']['AttributeType']
    helper.assertRequestError 'createTable', @data, messages.cannotBeNull('keySchema.rangeKeyElement.attributeType'), true, done

  it "returns an error on invalid keySchema.rangeKeyElement.attributeType", (done) ->
    @data['KeySchema']['RangeKeyElement']['AttributeType'] = 'Y'
    helper.assertRequestError 'createTable', @data, messages.invalidValueForEnum('keySchema.rangeKeyElement.attributeType', 'Y', ['N', 'S']), true, done

  it "returns an error on missing provisionedThroughput", (done) ->
    delete @data['ProvisionedThroughput']
    helper.assertRequestError 'createTable', @data, messages.cannotBeNull('provisionedThroughput'), true, done

  it "returns an error on missing provisionedThroughput.writeCapacityUnits", (done) ->
    delete @data['ProvisionedThroughput']['WriteCapacityUnits']
    helper.assertRequestError 'createTable', @data, messages.cannotBeNull('provisionedThroughput.writeCapacityUnits'), true, done

  it "returns an error on missing provisionedThroughput.readCapacityUnits", (done) ->
    delete @data['ProvisionedThroughput']['ReadCapacityUnits']
    helper.assertRequestError 'createTable', @data, messages.cannotBeNull('provisionedThroughput.readCapacityUnits'), true, done

  it "returns a failure on invalid serialization of readCapacityUnits", (done) ->
    delete @data['KeySchema']
    @data['ProvisionedThroughput']['ReadCapacityUnits'] = 'b'
    helper.assertRequestError 'createTable', @data, messages.cannotSerializeStringToLong(), false, done

  it "returns a failure on invalid serialization of writeCapacityUnits", (done) ->
    delete @data['KeySchema']
    @data['ProvisionedThroughput']['WriteCapacityUnits'] = 'b'
    helper.assertRequestError 'createTable', @data, messages.cannotSerializeStringToLong(), false, done

  describe 'persistence', ->
    beforeEach (done) -> helper.setupDatabase(done)
    afterEach -> helper.closeDatabase()

    it "saves the table information", (done) ->
      helper.async (db) ->
        alternator.createTable @data, (err, response) ->
          expect(err).toBeNull()
          expect(response.TableDescription.TableStatus).toEqual('CREATING')
          db.collection('ddb_tables').count {_id: 'users'}, (err, count) ->
            expect(count).toEqual(1)
            done()

    it "returns an error on duplicate tables", (done) ->
      helper.async (db) ->
        alternator.createTable @data, (err, response) ->
          alternator.createTable @data, (err, response) ->
            expect(err).toEqual(messages.duplicateTableName('users'))
            done()