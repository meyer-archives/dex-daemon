_ = require "lodash"

module.exports = (server, restify) ->
	urlHandler = require "./url-handler"

	staticOptions = {
		directory: global.dex_cache_dir
		maxAge: 60 * 60 * 24 * 365 * 69
		charSet: "UTF-8"
	}

	# Add CORS headers
	server.use restify.CORS()

	# Be nice to CURL
	server.pre restify.pre.userAgentConnection()

	# Module index
	server.get(
		"/"
		urlHandler.moduleIndex
	)

	# Generate all files for everything
	server.get(
		"/generate"
		urlHandler.moduleGenerate
	)

	# Generate all files for specific site
	server.get(
		/^\/generate\/(global|[^\/]+\.[^\/]+)$/
		urlHandler.moduleGenerate
	)

	# Get all data in stringy format
	server.get(
		"getdata"
		urlHandler.getModuleData
	)

	# Load module CSS/JS/JSON
	server.get(
		/^\/([^\/]+)\.(css|js|json)$/
		urlHandler.moduleContents
		restify.serveStatic staticOptions
	)

	# Module URL + cachebuster. It’s the future!
	server.get(
		/^\/(\d+)\/([^\/]+)\.(css|js|json)$/
		urlHandler.moduleContents
		restify.serveStatic staticOptions
	)

	# Config update
	server.post(
		/^\/([^\/]+)\.json$/
		urlHandler.configPost
		restify.serveStatic staticOptions
	)

	server.pre urlHandler.beforeRequest
	server.on "after", urlHandler.afterRequest
	server.on "uncaughtException", urlHandler.pageErrorHandler