mongo = require('mongodb')
messages = require('./messages')
validator = require('./validator')

class Alternator
  @commandLookup: 
    CreateTable: 'createTable'
    ListTables: 'listTables'
    DeleteTable: 'deleteTable'
    PutItem: 'putItem'

  @initialize: (config, callback) ->
    new mongo.Db(config.database, new mongo.Server(config.host, config.port, {})).open (err, db) ->
      return callback(err, null) if err?
      Alternator.db = db
      callback(null, db)


  @process: (request, response) =>
    target = request._devamodb.target;
    this[Alternator.commandLookup[target]](request.body, (err, r) ->
      if err?
        statusCode = 400
        body = err
      else
        statusCode = 200
        body = r
      response.writeHead(statusCode, {'Content-Type': 'application/x-amz-json-1.0'});
      response.end(JSON.stringify(body))
    )

  @systemCollection: ->
    @db.collection('ddb_tables')

  @createTable: (data, callback) =>
    return unless validator.createTable(data, callback)
    tableName = data.TableName

    doc =
      _id: tableName,
      details:
        CreationDateTime: new Date().getTime(),
        KeySchema: data.KeySchema,
        ProvisionedThroughput: data.ProvisionedThroughput,  
        TableName: tableName,
        TableStatus: 'ACTIVE'

    this.systemCollection().insert doc, {safe: true}, (err) ->
      return callback(messages.duplicateTableName(tableName), null) if err && err.code == 11000
      return callback(err, null) if err
      doc.details.TableStatus = 'CREATING'
      callback(null, {TableDescription: doc.details})

  @listTables: (data, callback) =>
    return unless validator.listTables(data, callback)

    selector = if data.ExclusiveStartTableName? then {_id: {$gt: data.ExclusiveStartTableName}} else {}
    options = {fields: {_id: true}, sort: [['_id', 'ascending']]}
    options.limit = data.Limit if data.Limit?
    
    this.systemCollection().find selector, options, (err, cursor) ->
      return callback(err, null) if err?
      cursor.toArray (err, values) ->
        return callback(err, null) if err?        
        cursor.count (err, count) ->
          return callback(err, null) if err?
          names = (value._id for value in values)
          response = {TableNames: names}
          response.LastEvaluatedTableName = names[names.length - 1] if names.length < count
          callback(null, response);

  @deleteTable: (data, callback) =>
    tableName = data.TableName
    return unless validator.deleteTable(data, callback)

    this.tableDetails tableName, (err, details) =>
      return callback(err, null) if err?
      return callback(messages.tableNotFound(tableName), null) unless details?

      this.systemCollection().remove {_id: tableName}, (err) =>
        return callback(err, null) if err?
        this.db.collection(tableName).drop (err) ->
          details.TableStatus = 'DELETING'
          callback(null, details)

  @putItem: (data, callback) =>
    this.tableDetails data.TableName, (err, details) =>
      return unless validator.putItem(data, details, callback)
      document = {}
      for key, value of data.Item
        document[key] = if value['N']? then value['N'] else value['S'] #fix this crap, it's everwhere

      hashKey = details.KeySchema.HashKeyElement.AttributeName
      rangeKey = details.KeySchema.RangeKeyElement?.AttributeName
      if rangeKey?
        document._id = {}
        document._id[hashKey] = document[hashKey]
        document._id[rangeKey] = document[rangeKey]
        delete document[rangeKey]
      else
        document._id = document[hashKey]

      delete document[hashKey]
      collection = this.db.collection(data.TableName)
      collection.findOne {_id: document._id}, (err, value) =>
        collection.update {_id: document._id}, document, {safe: true, upsert: true}, (err, document) =>
          return callback(err, null) if err?
          value = if data.ReturnValue == 'ALL_OLD' then this.fixId(value, hashKey, rangeKey) else undefined
          callback(null, value)
  
  @tableDetails: (name, callback) =>
    this.systemCollection().findOne {_id: name}, (err, value) ->
      return callback(err, null) if err?
      callback(null, if value? then value.details else null)

  @fixId: (document, hashKey, rangeKey) =>
    return undefined unless document?
    if rangeKey?
      document[key] = value for key, value of document._id
    else
      document[hashKey] = document._id
    delete document._id
    document


module.exports = Alternator