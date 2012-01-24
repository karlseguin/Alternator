bodyParser =  ->
  bodyParser = (request, response, next) ->
    return next() if request._bodyParser
    request._bodyParser = true

    buffer = new Buffer(parseInt(request.headers['content-length']))
    read = 0
    request.on 'data', (chunk) ->
      chunk.copy(buffer, read)
      read += chunk.length
    request.on 'end', ->
      request.body = if buffer.length == 0 then {} else JSON.parse(buffer.toString('utf8'))
      next()

module.exports = bodyParser