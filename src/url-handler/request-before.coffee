colors = require "colors"

module.exports = (request, response, next) ->
	# Set default charset
	response.charSet("utf-8")

	console.log ("#{request.method}".bold + " #{request.url}").green

	do next