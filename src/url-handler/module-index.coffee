configUtils = require "../utils/config"

module.exports = (request, response, next) ->
	config = configUtils.getConfig()
	response.send 200, config.modulesByHostname.enabled
	do next