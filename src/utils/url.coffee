_ = require "lodash"

module.exports.cleanHostname = (hostname) ->
	# Remove www/ww[0-9]
	hostname = hostname.replace(/ww[\dw]\./, "")
	hostname = _.trim(hostname, "/")
	hostname