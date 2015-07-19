#!/usr/bin/env coffee

fs = require "fs-extra"
path = require "path"
colors = require "colors"
restify = require "restify"

pkg = require "./package.json"
expandPath = require("./src/utils/path").expand
logger = require "./src/utils/log"
getRequiredEnvVar = require("./src/utils/env").getRequiredVar

# Remember cwd
global.dex_dir = process.cwd()

# Change to user-specified folder
global.dex_file_dir = expandPath getRequiredEnvVar("DEX_FILE_DIR")
fs.mkdirpSync global.dex_file_dir
global.dex_file_dir = fs.realpathSync global.dex_file_dir
process.chdir global.dex_file_dir

# Set config file location
global.dex_yaml_config_file = path.resolve("enabled.yaml")
fs.ensureFileSync global.dex_yaml_config_file

# Set cache folder location
global.dex_cache_dir = path.resolve(".dex-cache")
fs.mkdirpSync global.dex_cache_dir

serverOptions =
	name: pkg.name
	version: pkg.version
	log: logger
	httpsServerOptions:
		key:  fs.readFileSync path.join(global.dex_dir, "ssl", "server.key")
		cert: fs.readFileSync path.join(global.dex_dir, "ssl", "server.crt")

# Fire up the server
server = restify.createServer(serverOptions)

server.pre restify.pre.userAgentConnection()

server.listen process.env.DEX_PORT || 3131, ->
	console.log "Server running at %s", server.url
	console.log "PWD: #{process.cwd()}"
	console.log "=================".grey

require("./src/routes")(server, restify)