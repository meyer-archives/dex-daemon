_ = require "lodash"
fs = require "fs-extra"
path = require "path"
glob = require "glob"
urlUtils = require "../utils/url"
configUtils = require "../utils/config"
logger = require "../utils/log"

compileSiteFile = require "../utils/buildfile"

sass = require "node-sass"
coffee = require "coffee-script"

module.exports = (req, res, next) ->
	config = configUtils.getConfig()

	{
		metadata
		modulesByHostname
	} = config

	prams = _.values(req.params)

	switch prams.length
		when 0
			fs.deleteSync global.dex_cache_dir
			fs.mkdirpSync global.dex_cache_dir

			["404"].concat(Object.keys modulesByHostname.enabled).forEach (hostname) ->
				buildSiteFiles urlUtils.cleanHostname(hostname), config

			res.send 200, config
			do next

		when 1
			hostname = urlUtils.cleanHostname(prams[0])
			if modulesByHostname.enabled[hostname]
				siteFiles = buildSiteFiles(hostname, config)
			else
				logger.info "modulesByHostname does not contain \"#{prams[0]}\""
				siteFiles = buildSiteFiles("404", config)

			res.send 200, siteFiles
			do next

		else
			logger.error "TOO MANY COOKS:", prams

globArray = (d) ->
	if Array.isArray(d) && d.length > 1
		"{#{d.join(",")}}"
	else
		"#{d}"

buildFile = (hostname, allFiles, enabledFiles) ->
	returnData = enabledFiles.map(compileSiteFile)

	"""
	/*
	#{configUtils.getDexVersionString()}
	#{configUtils.getDateString()}

	#{
	allFiles.map((m) ->
		if ~enabledFiles.indexOf(m)
			"[x] #{m}"
		else
			"[ ] #{m}"
	).join("\n")
	}
	*/

	#{_.remove(returnData, (n) -> n).join("\n\n/***********/\n\n")}
	"""

buildSiteFiles = (hostname, config) ->
	config ?= configUtils.getConfig()

	{
		metadata
		modulesByHostname
	} = config

	# Files to write (maybe)
	jsFilename = path.join(global.dex_cache_dir, "#{hostname}.js")
	cssFilename = path.join(global.dex_cache_dir, "#{hostname}.css")
	jsonFilename = path.join(global.dex_cache_dir, "#{hostname}.json")

	try fs.unlinkSync jsFilename
	try fs.unlinkSync cssFilename
	try fs.unlinkSync jsonFilename

	globtions = _.extend configUtils.globtions, {nodir: true}

	# Enabled modules
	cssModules = modulesByHostname.enabled[hostname] || []
	jsModules = [hostname].concat cssModules

	jsFiles = []
	cssFiles = []

	enabledJSFiles = []
	enabledCSSFiles = []

	if hostname == "404"
		siteConfig = {
			site_available:   modulesByHostname.utilities
			site_enabled:     []
			global_available: modulesByHostname.available["global"]
			global_enabled:   modulesByHostname.enabled["global"]
			metadata
		}

		fs.writeFile jsFilename, "/* I can't even. */"
		fs.writeFile cssFilename, "/* Nothin' here, man. */"
		fs.writeFile jsonFilename, JSON.stringify(siteConfig, null, "  ")

		logger.info files: [jsFilename, cssFilename, jsonFilename], "Built default files"

		return siteConfig

	fileList = []

	if process.cwd() != global.dex_file_dir
		logger.error {actualCWD: process.cwd(), expectedCWD: global.dex_file_dir}, "PWD has been unexpectedly changed."
		process.chdir global.dex_file_dir

	# Start with available utilities
	if hostname != "global"
		jsFiles = glob.sync("utilities/*/*.{js,coffee}", globtions)
		cssFiles = glob.sync("utilities/*/*.{css,scss,sass}", globtions)

	jsFiles = jsFiles.concat(
		glob.sync("#{hostname}/*.{js,coffee}", globtions)
		glob.sync("#{hostname}/*/*.{js,coffee}", globtions)
	)
	cssFiles = cssFiles.concat glob.sync("#{hostname}/*/*.{css,scss,sass}", globtions)

	# Build array of JS and CSS files
	if jsModules.length > 0
		enabledJSFiles = glob.sync("#{globArray jsModules}/*.{js,coffee}", globtions)

	if cssModules.length > 0
		enabledCSSFiles = glob.sync("#{globArray cssModules}/*.{css,scss,sass}", globtions)

	# Build JS, CSS, and JSON files for hostname
	if enabledJSFiles.length > 0
		jsData = buildFile(hostname, jsFiles, enabledJSFiles)
		fileList.push jsFilename
		fs.writeFile jsFilename, jsData

	if enabledCSSFiles.length > 0
		cssData = buildFile(hostname, cssFiles, enabledCSSFiles)
		fileList.push cssFilename
		fs.writeFile cssFilename, cssData

	siteConfig = {}

	if hostname != "global"
		if (jsModules.length + cssModules.length) > 0
			siteConfig = {
				site_available:   modulesByHostname.available[hostname] || []
				site_enabled:     modulesByHostname.enabled[hostname]   || []
				global_available: modulesByHostname.available["global"] || []
				global_enabled:   modulesByHostname.enabled["global"]   || []
				metadata
			}
			jsonData = JSON.stringify(siteConfig, null, "  ")

			fileList.push  jsonFilename
			fs.writeFile jsonFilename, jsonData

	logger.info {
		modules: modulesByHostname.enabled[hostname]
		files: fileList
	}, "Built files for #{hostname}"

	siteConfig