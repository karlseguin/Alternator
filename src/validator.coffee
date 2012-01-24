messages = require('./messages')
util = require('util')

class Validator
  @createTable: (data, callback) ->
    return unless Validator.tableName(data.TableName, callback) 
    return unless Validator.serializeToNumber(data.ProvisionedThroughput?.WriteCapacityUnits, callback)
    return unless Validator.serializeToNumber(data.ProvisionedThroughput?.ReadCapacityUnits, callback)

    errors = []
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

  @notNull: (value, name, errors) ->
    unless value?
      errors.push(messages.cannotBeNull(name))
      return false
    return true

  @handleErrors: (errors, callback) ->
    return true if errors.length == 0

    plural = if errors.length == 1 then '' else 's'
    error = 
      __type: errors[0].__type
      message: util.format("%d validation error%s detected: %s", errors.length, plural, (error.message for error in errors).join('; '))
    callback(error, null)
    false


module.exports = Validator