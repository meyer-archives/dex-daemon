_ = require "lodash"

module.exports = (request, response, next) ->
	[category, module] = _.values request.params

	body = "module-create (category: #{category}, module: #{decodeURI module})"

	response.send 200, body
	console.log body

	do next