_ = require "lodash"
fs = require "fs-extra"
path = require "path"

module.exports = (request, response, next) ->
	filename = path.resolve path.join(global.dex_cache_dir, request.url)

	# Prevent traversal
	if !~filename.indexOf(global.dex_cache_dir)
		next new Error("URL is invalid (#{filename}, #{global.dex_cache_dir})")
		return

	[hostname, ext] = _.values request.params

	# Already generated
	if !fs.existsSync filename
		request.url = "/404.#{ext}"

	do next
	return