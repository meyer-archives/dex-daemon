module.exports = (request, response, route, error) ->
	console.log "Error!", error
	setTimeout ->
		process.exit(1)
	, 300
	return