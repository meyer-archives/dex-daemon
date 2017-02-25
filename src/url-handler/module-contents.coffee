_ = require "lodash"
fs = require "fs-extra"
path = require "path"
urlUtils = require "../utils/url"

module.exports = (request, response, next) ->
	prams = _.values request.params
	[hostname, ext] = prams.slice(-2)
	console.log "hostname, ext:", hostname, ext

	cleanHostname = urlUtils.cleanHostname(hostname)

	# Clean off cachebuster if it's present
	request.url = "/#{hostname}.#{ext}"

	# Check to see if the file exists
	filename = path.resolve path.join(global.dex_cache_dir, request.url)

	console.log "#{filename}"

	# Prevent traversal
	if !~filename.indexOf(global.dex_cache_dir)
		return next new Error("URL is invalid (#{filename}, #{global.dex_cache_dir})")

	# Temporary redirect if no cachebuster, else permanent
	if !fs.existsSync filename
		console.log "PRAMS:", prams
		console.log "Redirect:", if prams.length == 2 then "temp" else "permanent"
		# response.header 'Location', "/404.#{ext}"
		# response.send if prams.length == 2 then 302 else 301
		# return next(false)

	# Redirect to clean hostname if necessary
	if cleanHostname != hostname
		console.log "Hostname diff: #{cleanHostname} != #{hostname}"
		# response.header 'Location', request.url.replace(hostname, cleanHostname)
		# response.send 301
		# return next(false)

	next()