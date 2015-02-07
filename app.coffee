#!/usr/bin/env coffee

fs = require "fs-extra"
path = require "path"
restify = require "restify"

pkg = require "./package.json"

# Saving cwd as it's about to change
global.dex_dir = process.cwd()
global.dex_public_dir = path.join(global.dex_dir, "public")

global.dex_yaml_config_file = path.resolve \
	(process.env.DEX_CONFIG_DIR || global.dex_public_dir), ".dex-enabled.yaml"

global.dex_cache_dir = path.resolve \
	(process.env.DEX_CACHE_DIR || global.dex_public_dir), ".dex-cache"

global.dex_file_dir = path.resolve \
	process.env.DEX_FILE_DIR || path.join(global.dex_public_dir, "demo-modules")

process.chdir global.dex_file_dir

# Attempt to resolve symlinks
try global.dex_yaml_config_file = fs.realpathSync global.dex_yaml_config_file
try global.dex_cache_dir = fs.realpathSync global.dex_cache_dir

serverOptions =
	name: pkg.name
	version: pkg.version
	httpsServerOptions:
		key:  fs.readFileSync path.join(global.dex_dir, "ssl", "server.key")
		cert: fs.readFileSync path.join(global.dex_dir, "ssl", "server.crt")

# Fire up the server
server = restify.createServer(serverOptions)

server.pre restify.pre.userAgentConnection()

server.listen process.env.DEX_PORT || 3131, ->
	console.log "Server running at %s", server.url

require("./src/routes")(server, restify)