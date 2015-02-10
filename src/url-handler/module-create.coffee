_ = require "lodash"

module.exports = (request, response, next) ->
	[category, mod] = _.values request.params

	body = "module-create (category: #{category}, module: #{decodeURI mod})"

	response.send 200, body
	console.log body

	do next