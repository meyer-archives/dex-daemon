_ = require "lodash"

module.exports = (server, restify) ->
	urlHandler = require "./url-handler"

	staticOptions = {
		directory: global.dex_cache_dir
		maxAge: 60 * 60 * 12 # 12 hours
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
		/^\/(global|[^\/]+\.[^\/]+)\.(css|js|json)$/
		urlHandler.moduleContents
		restify.serveStatic staticOptions
	)

	# Config update
	server.post(
		/^\/(global|[^\/]+\.[^\/]+)\.json$/
		urlHandler.configPost
		restify.serveStatic staticOptions
	)

	# Edit existing modules
	server.get(
		/^\/edit\/([^\/]+)/
		urlHandler.moduleEdit
	)

	# Create new modules
	server.get(
		/^\/create\/(global|utilities|[^\/]+\.[^\/]+)\/([^\/]+)$/
		urlHandler.moduleCreate
	)

	server.pre urlHandler.beforeRequest
	server.on "after", urlHandler.afterRequest
	server.on "uncaughtException", urlHandler.pageErrorHandler