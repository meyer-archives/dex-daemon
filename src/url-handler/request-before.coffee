colors = require "colors"

module.exports = (request, response, next) ->
	response.charSet = 'utf-8'
	console.log ("#{request.method}".bold + " #{request.url}").green
	do next