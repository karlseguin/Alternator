contextParser =  ->
  contextParser = (request, response, next) ->
    return next() if request._contextParser
    request._contextParser = true
    target = request.headers['x-amz-target'].split('.')
    request._devamodb = {target: target[target.length - 1]}
    return next()

module.exports = contextParser