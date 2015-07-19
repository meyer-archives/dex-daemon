fs = require "fs"
path = require "path"

expandPath = (p) ->
	# TODO: Cross-platform home dir
	if p.charAt(0) == "~"
		p = path.join(process.env.HOME, p.slice(1))
	path.resolve p

module.exports.expand = expandPath