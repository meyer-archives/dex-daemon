colors = require "colors"

module.exports = (request, response, e) ->
	console.log "Response: #{response.statusCode}"
	console.log "=================".grey