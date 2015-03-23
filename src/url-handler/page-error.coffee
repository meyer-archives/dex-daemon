logger = require "../utils/log"

module.exports = (request, response, route, error) ->
	logger.error {error: error}, "Error!" # error
	setTimeout ->
		process.exit(1)
	, 300
	return