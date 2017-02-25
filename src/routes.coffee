_ = require "lodash"

genRegex = "generate/"
modRegex = "(global|[^\/]+\\.[^\/]+)"
cbRegex = "(?:\d+\/)?" # optional cachebuster

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

	# Generate files for a specific site, load ’em
	server.get(
		///^\/#{genRegex}#{modRegex}\.(css|js|json)$///
		urlHandler.moduleGenerate
		urlHandler.moduleContents
		restify.serveStatic staticOptions
	)

	# Load module CSS/JS/JSON
	server.get(
		///^\/(?:\d+\/)?#{modRegex}\.(css|js|json)$///
		urlHandler.moduleContents
		restify.serveStatic staticOptions
	)

	# Update YAML config file
	server.post(
		///^\/#{modRegex}\.json$///
		urlHandler.configPost
		restify.serveStatic staticOptions
	)

	server.pre urlHandler.beforeRequest
	server.on "after", urlHandler.afterRequest
	server.on "uncaughtException", urlHandler.pageErrorHandler