module.exports = (server, restify) ->
	urlHandler = require "./url-handler"

	server.use restify.CORS()
	server.pre restify.pre.userAgentConnection()

	# Module index
	server.get(
		"/"
		urlHandler.moduleIndex
	)

	server.get(
		"/generate"
		urlHandler.moduleGenerate
	)

	# Load module CSS/JS/JSON
	server.get(
		/^\/([^\/]+\.[^\/]+)\.(css|js|json)$/
		urlHandler.moduleContents
		restify.serveStatic { directory: global.dex_cache_dir }
	)

	server.get(
		/^\/generate\/([^\/]+\.[^\/]+)(\.(css|json|js))?$/
		urlHandler.moduleGenerateSite
	)

	# Config update
	server.post(
		/^\/([^\/]+\.[^\/]+)\.json$/
		urlHandler.configPost
		restify.serveStatic { directory: global.dex_cache_dir }
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

	# Load static resources
	server.get(
		/^\/([^\/]+)\/([^\/]+)\/([^\/]+)\.(png|svg|json|js|css)$/
		urlHandler.serveStatic
		restify.serveStatic { directory: global.dex_file_dir }
	)

	server.pre urlHandler.beforeRequest
	server.on "after", urlHandler.afterRequest

	# server.use urlHandler.notFoundHandler

	server.on "uncaughtException", urlHandler.pageErrorHandler