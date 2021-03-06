messages = require('./messages')
util = require('util')

class Validator
  @tablePattern: /^[a-zA-Z0-9_.-]+$/

  @createTable: (data, callback) ->
    return unless Validator.tableName(data.TableName, callback) 
    return unless Validator.serializeToNumber(data.ProvisionedThroughput?.WriteCapacityUnits, callback)
    return unless Validator.serializeToNumber(data.ProvisionedThroughput?.ReadCapacityUnits, callback)

    errors = []
    Validator.validPattern(data.TableName, 'tableName', Validator.tablePattern, errors)
    if Validator.notNull(data.KeySchema, 'keySchema', errors)
      if Validator.notNull(data.KeySchema.HashKeyElement, 'keySchema.hashKeyElement', errors)
        Validator.notNull(data.KeySchema.HashKeyElement.AttributeName, 'keySchema.hashKeyElement.attributeName', errors)
        Validator.validType(data.KeySchema.HashKeyElement.AttributeType, 'keySchema.hashKeyElement.attributeType', errors)
      if data.KeySchema.RangeKeyElement?
        Validator.notNull(data.KeySchema.RangeKeyElement.AttributeName, 'keySchema.rangeKeyElement.attributeName', errors)
        Validator.validType(data.KeySchema.RangeKeyElement.AttributeType, 'keySchema.rangeKeyElement.attributeType', errors)
    if Validator.notNull(data.ProvisionedThroughput, 'provisionedThroughput', errors)
        Validator.notNull(data.ProvisionedThroughput.WriteCapacityUnits, 'provisionedThroughput.writeCapacityUnits', errors)
        Validator.notNull(data.ProvisionedThroughput.ReadCapacityUnits, 'provisionedThroughput.readCapacityUnits', errors)

    Validator.handleErrors(errors, callback)

  @listTables: (data, callback) ->
    return unless typeof(data.ExclusiveStartTableName) == 'undefined' || Validator.tableName(data.ExclusiveStartTableName, callback)
    return unless Validator.serializeToNumber(data.limit, callback)
    return true

  @deleteTable: (data, callback) ->
    return unless Validator.tableName(data.TableName, callback) 
    errors = []
    Validator.validPattern(data.TableName, 'tableName', Validator.tablePattern, errors)
    Validator.handleErrors(errors, callback)

  @putItem: (data, details, callback) ->
    return unless Validator.crudDetails(data, 'Item', details, callback)
    return unless Validator.validReturnValue(data.ReturnValue, callback)
  
    errors = []
    Validator.validPattern(data.TableName, 'tableName', Validator.tablePattern, errors)
    Validator.notNull(data.Item, 'item', errors)

    Validator.handleErrors(errors, callback)
       
  @tableName: (name, callback) ->
    if !name? || name.length < 3 || name.length > 255
      callback(messages.invalidTableName(), null) 
      return false
    return true

  @serializeToNumber: (value, callback) ->
    if value? && isNaN(parseInt(value))
      callback(messages.cannotSerializeStringToLong(), null)
      return false
    return true

  @validType: (value, name, errors) ->
    return unless Validator.notNull(value, name, errors)
    unless value == 'N' || value == 'S'
      errors.push(messages.invalidValueForEnum(name, value,  ['N', 'S']))
      return false
    return true

  @validPattern: (value, name, pattern, errors) ->
    return true if pattern.test(value)
    errors.push(messages.invalidPattern(name, value, pattern))
    return false

  @notNull: (value, name, errors) ->
    unless value?
      errors.push(messages.cannotBeNull(name))
      return false
    return true

  @keysArePresent: (value, details, callback) ->
    unless value[details.KeySchema.HashKeyElement.AttributeName]?
      return callback(messages.missingKey(), null) 
    
    unless details.KeySchema.RangeKeyElement?
      return true

    unless value[details.KeySchema.RangeKeyElement.AttributeName]?
      return callback(messages.missingKey(), null) 

    return true

  @keysAreTyped: (value, details, callback) ->
    expected = details.KeySchema.HashKeyElement.AttributeType
    unless value[details.KeySchema.HashKeyElement.AttributeName][expected]?
      return callback(messages.invalidKeyType(expected, if expected == 'S' then 'N' else 'S'), null)
    
    unless details.KeySchema.RangeKeyElement?
      return true

    expected = details.KeySchema.RangeKeyElement.AttributeType
    unless value[details.KeySchema.RangeKeyElement.AttributeName][expected]?
      return callback(messages.invalidKeyType(expected, if expected == 'S' then 'N' else 'S'), null)

    return true

  @crudDetails: (data, keys, details, callback) ->
    unless Validator.tableName(data.TableName, callback) 
      return false

    unless details?
      return callback(messages.resourceNotFound(), null) 
    
    unless data[keys]?
      return true

    unless Validator.keysArePresent(data[keys], details, callback)
      return false

    unless Validator.keysAreTyped(data[keys], details, callback)
      return false

    return true
  
  @validReturnValue: (value, callback) ->
    return true unless value? 
    return true if value == 'ALL_OLD' || value == 'NONE'
    callback(messages.invalidReturnValue(), null)
    return false

  @handleErrors: (errors, callback) ->
    return true if errors.length == 0

    plural = if errors.length == 1 then '' else 's'
    error = 
      __type: errors[0].__type
      message: util.format("%d validation error%s detected: %s", errors.length, plural, (error.message for error in errors).join('; '))
    callback(error, null)
    false


module.exports = Validator