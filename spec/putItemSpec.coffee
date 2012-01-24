helper = require('./helper')
alternator = helper.alternator
messages = require('../src/messages')

describe 'putItem', ->

  beforeEach (done) -> 
    @data = Helper.validData()
    done()

  it "returns an error on null table name", (done) ->
    @data.TableName = null
    helper.assertRequestError 'putItem', @data, messages.invalidTableName(), false, done

  it "returns an error on short table name", (done) ->
    @data.TableName = 'b'
    helper.assertRequestError 'putItem', @data, messages.invalidTableName(), false, done

  it "returns an error on long table name", (done) ->
    @data.TableName = (n for n in [1..256]).join('')
    helper.assertRequestError 'putItem', @data, messages.invalidTableName(), false, done

  
class Helper
  @validData: ->
    TableName: 'users'
    Item:
      Id: {1:'N'}
      Name: {'Duncan':'S'}