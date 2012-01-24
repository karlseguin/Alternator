util = require('util')
class Messages
  @duplicateTableName: (name) ->
    return {
      __type: 'com.amazonaws.dynamodb.v20111205#ResourceInUseException'
      message: util.format('Attempt to change a resource which is still in use: Duplicate table name: %s', name)
    }
  @invalidTableName: ->
    return {
      __type: 'com.amazon.coral.validate#ValidationException'
      message: "The paramater 'tableName' must be at least 3 characters long and at most 255 characters long"
    }
  @invalidPattern: (name, value, pattern) ->
    return {
      __type: 'com.amazon.coral.validate#ValidationException'
      message: util.format("Value '%s' at '%s' failed to satisfy constraint: Member must satisfy regular expression pattern:%s", value, name, pattern)
    }
  @cannotSerializeStringToLong: ->
    return {
      __type: 'com.amazon.coral.service#SerializationException'
      message: "class java.lang.String can not be converted to an Long"
    }
  @tableNotFound: (name) ->
    return {
      __type: 'com.amazonaws.dynamodb.v20111205#ResourceNotFoundException'
      message: util.format('Requested resource not found: Table: %s not found', name)
    }
  @cannotBeNull: (name) ->
    return {
      __type: 'com.amazon.coral.validate#ValidationException'
      message: util.format("Value null at '%s' failed to satisfy constraint: Member must not be null", name)
    }
  @invalidValueForEnum: (name, value, constraint) ->
    return {
      __type: 'com.amazon.coral.validate#ValidationException'
      message: util.format("Value '%s' at '%s' failed to satisfy constraint: Member must satisfy enum value set: %s", value, name, JSON.stringify(constraint))
    }
  @resourceNotFound: ->
    return {
      __type: 'com.amazonaws.dynamodb.v20111205#ResourceNotFoundException'
      message: 'Requested resource not found'
    }  
  @missingKey: ->
    return {
      __type: 'com.amazon.coral.validate#ValidationException'
      message: 'One or more parameter values were invalid: Missing the key id in the item'
    }
  @invalidKeyType: (expected, actual) ->
    return {
      __type: 'com.amazon.coral.validate#ValidationException'
      message: util.format('One or more parameter values were invalid: Type mismatch for key id expected: %s actual: %s', expected, actual)
    }
     

module.exports = Messages