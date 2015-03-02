_ = require "lodash"
fs = require "fs-extra"
path = require "path"
glob = require "glob"
urlUtils = require "../utils/url"
configUtils = require "../utils/config"

sass = require "node-sass"
coffee = require "coffee-script"

module.exports = (request, response, next) ->
	config = configUtils.getConfig()

	{
		metadata
		modulesByHostname
	} = config

	prams = _.values(request.params)

	switch prams.length
		when 0
			fs.deleteSync global.dex_cache_dir
			fs.mkdirpSync global.dex_cache_dir

			["404"].concat(Object.keys modulesByHostname.enabled).forEach (hostname) ->
				buildSiteFiles urlUtils.cleanHostname(hostname), config

			response.send 200, config
			do next

		when 1
			hostname = urlUtils.cleanHostname(prams[0])
			if modulesByHostname.enabled[hostname]
				siteFiles = buildSiteFiles(hostname, config)
			else
				console.log "modulesByHostname does not contain \"#{prams[0]}\""
				siteFiles = buildSiteFiles("404", config)

			response.send 200, siteFiles
			do next

		else
			console.error "TOO MANY COOKS:", prams

globArray = (d) ->
	if Array.isArray(d) && d.length > 1
		"{#{d.join(",")}}"
	else
		"#{d}"

buildFile = (hostname, allFiles, enabledFiles) ->
	returnData = allFiles.map (f) ->
		return false unless ~enabledFiles.indexOf(f)

		data = fs.readFileSync path.join(global.dex_file_dir, f), encoding: "utf8"

		c = ""
		ext = path.extname(f)

		switch ext
			when ".scss", ".sass"
				try
					data = sass.renderSync({data}).css
					c = " (compiled)"
				catch e
					console.error "\nSass compile error".red
					console.error "#{e}"
					data = "/* Sass compile error: #{e} */"

			when ".coffee"
				try
					data = coffee.compile(data)
					c = " (compiled)"
				catch e
					console.error "\nCoffeeScript compile error".red
					console.error "#{path.join global.dex_file_dir, f}:#{e.location.first_line+1}:#{e.location.first_column+1}".underline
					console.log "\n#{e}"
					data = "console.error(\"CoffeeScript compile error: #{e.toString()}\");"

		switch ext
			when ".css", ".scss", ".sass"
				"""
				/* @begin #{f}#{c} */

				#{data}

				/* @end #{f}#{c} */
				"""

			when ".js", ".coffee"
				"""
				console.group("#{f}#{c}");

				#{data}

				console.groupEnd();
				"""

			else
				console.error "Unsupported filetype: #{ext}"

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
		console.log "Building default files".underline

		siteConfig = {
			site_available:   modulesByHostname.utilities
			site_enabled:     []
			global_available: modulesByHostname.available["global"]
			global_enabled:   modulesByHostname.enabled["global"]
			metadata
		}

		console.log "[x] #{jsFilename}"
		fs.writeFile jsFilename, "/* I can't even. */"

		console.log "[x] #{cssFilename}"
		fs.writeFile cssFilename, "/* Nothin' here, man. */"

		console.log "[x] #{jsonFilename}"
		fs.writeFile jsonFilename, JSON.stringify(siteConfig, null, "  ")

		console.log ""

		return siteConfig

	console.log "Building files for #{hostname} (#{(modulesByHostname.enabled[hostname] || []).length})".underline

	if process.cwd() != global.dex_file_dir
		console.error "PWD has been changed!"
		console.error "#{process.cwd()} != #{global.dex_file_dir}"
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
		console.log "[x] #{jsFilename}"
		fs.writeFile jsFilename, jsData
	else
		console.log "[ ] #{jsFilename}"

	if enabledCSSFiles.length > 0
		cssData = buildFile(hostname, cssFiles, enabledCSSFiles)
		console.log "[x] #{cssFilename}"
		fs.writeFile cssFilename, cssData
	else
		console.log "[ ] #{cssFilename}"

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

			console.log "[x] #{jsonFilename}"
			fs.writeFile jsonFilename, jsonData
		else
			console.log "[ ] #{jsonFilename}"

	console.log ""

	siteConfig