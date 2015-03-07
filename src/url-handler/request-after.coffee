colors = require "colors"

module.exports = (request, response, e) ->
	console.log ("#{request.method}".bold + " #{request.originalURL}").green
	console.log "Response: #{response.statusCode.toString().bold}"

	if ~[301, 302].indexOf response.statusCode
		console.log "Redirecting to #{response.getHeader("Location").toString().bold}"

	console.log "=================".grey