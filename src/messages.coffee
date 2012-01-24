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
     

module.exports = Messages