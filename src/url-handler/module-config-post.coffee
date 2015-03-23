logger = require "../utils/log"

module.exports = (req, res, next) ->
	body = "module-config-update (params: #{req.params.join ", "})"

	res.send 200, body
	logger.debug body

	do next