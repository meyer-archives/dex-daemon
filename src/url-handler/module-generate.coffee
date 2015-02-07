_ = require "lodash"
fs = require "fs-extra"
path = require "path"
glob = require "glob"
configUtils = require "../utils/config"

sass = require "node-sass"
coffee = require "coffee-script"

module.exports = (request, response, next) ->
	config = configUtils.getConfig()

	{
		metadata
		modulesByHostname
	} = config

	fs.deleteSync global.dex_cache_dir
	fs.mkdirSync global.dex_cache_dir

	Object.keys(modulesByHostname.enabled).forEach (hostname) ->
		buildSiteFiles(hostname, config)

	response.send 200, config
	do next


buildSiteFiles = (hostname, config) ->
	config ?= configUtils.getConfig()

	{
		metadata
		modulesByHostname
	} = config

	console.log "Building site files for #{hostname} (#{(modulesByHostname.enabled[hostname] || []).length})".underline

	globtions = _.extend configUtils.globtions, {nodir: true}

	globalModules =
		available: modulesByHostname.available["global"] || []
		enabled:   modulesByHostname.enabled["global"] || []

	jsModules = [].concat hostname, (modulesByHostname.enabled[hostname] || [])
	cssModules = [].concat (modulesByHostname.enabled[hostname] || [])

	globalJSModules = modulesByHostname.enabled["global"] || []
	globalCSSModules = modulesByHostname.enabled["global"] || []

	###
	These arrays have to be built with several globs concatenated together
	because node-glob doesn't preserve any sort of order.
	###
	jsFiles = []
	globalJSFiles = glob("global/*/*.{js,coffee}", globtions)
	enabledJSFiles = glob("{#{globalJSModules.join(",")}}/*.{js,coffee}", globtions)

	cssFiles = []
	globalCSSFiles = glob("global/*/*.{css,scss,sass}", globtions)
	enabledCSSFiles = glob("{#{globalCSSModules.join(",")}}/*.{css,scss,sass}", globtions)

	unless hostname == "global"
		jsFiles = [].concat(
			glob("utilities/*.{js,coffee}", globtions)
			glob("#{hostname}/*.{js,coffee}", globtions)
			glob("#{hostname}/*/*.{js,coffee}", globtions)
		)

		enabledJSFiles = enabledJSFiles.concat(
			glob("{#{jsModules.join(",")}}/*.{js,coffee}", globtions)
		)

		cssFiles = [].concat(
			glob("utilities/*.{css,scss,sass}", globtions)
			glob("#{hostname}/*/*.{css,scss,sass}", globtions)
		)

		enabledCSSFiles = enabledCSSFiles.concat(
			glob("{#{cssModules.join(",")}}/*.{css,scss,sass}", globtions)
		)

	if enabledJSFiles.length > 0

		jsFileHeader = [].concat(
			"/*"
			"#{configUtils.getDexVersionString()}"
			"#{configUtils.getDateString()}"
			""
		)

		jsFileHeader = jsFileHeader.concat(
			"Global JS files"
			"---------------"
			_.map globalJSFiles, (m) ->
				if ~enabledJSFiles.indexOf(m)
					"[x] #{m}"
				else
					"[ ] #{m}"
			""
			"Enabled global modules"
			"----------------------"
			globalJSModules
			""
		)

		unless hostname == "global"
			jsFileHeader = jsFileHeader.concat(
				"Host-specific JS files"
				"----------------------"
				_.map jsFiles, (m) ->
					if ~enabledJSFiles.indexOf(m)
						"[x] #{m}"
					else
						"[ ] #{m}"
				""
				"Enabled host-specific modules"
				"-----------------------------"
				jsModules
				""
			)

		jsFileHeader.push "*/"

		jsFileHeader = jsFileHeader.join("\n") + "\n\n"

		jsData = jsFileHeader + [].concat(globalJSFiles, jsFiles).map((f) ->
			return unless ~enabledJSFiles.indexOf(f)

			data = fs.readFileSync path.join(global.dex_file_dir, f), encoding: "utf8"

			if path.extname(f) == ".coffee"
				try
					data = coffee.compile(data)
				catch e
					data = "// CoffeeScript error: #{e}"

			[
				"console.groupCollapsed('#{f}');"
				data
				"console.groupEnd();"
				""
			].join("\n\n")
		).join("")

		console.log "Writing", path.join(global.dex_cache_dir, "#{hostname}.js")
		fs.writeFile path.join(global.dex_cache_dir, "#{hostname}.js"), jsData

	if enabledCSSFiles.length > 0
		cssFileHeader = [].concat(
			"/*"
			"#{configUtils.getDexVersionString()}"
			"#{configUtils.getDateString()}"
			""
		)

		cssFileHeader = cssFileHeader.concat(
			"Global CSS files"
			"----------------"
			_.map globalCSSFiles, (m) ->
				if ~enabledCSSFiles.indexOf(m)
					"[x] #{m}"
				else
					"[ ] #{m}"
			""
			"Enabled global modules"
			"----------------------"
			globalCSSModules
			""
		)

		unless hostname == "global"
			cssFileHeader = cssFileHeader.concat(
				"Host-specific CSS files"
				"----------------------"
				_.map cssFiles, (m) ->
					if ~enabledCSSFiles.indexOf(m)
						"[x] #{m}"
					else
						"[ ] #{m}"
				""
				"Enabled host-specific modules"
				"-----------------------------"
				cssModules
				""
			)

		cssFileHeader.push "*/"

		cssFileHeader = cssFileHeader.join("\n") + "\n\n"

		cssData = cssFileHeader + [].concat(globalCSSFiles, cssFiles).map((f) ->
			return unless ~enabledCSSFiles.indexOf(f)

			data = fs.readFileSync path.join(global.dex_file_dir, f), encoding: "utf8"

			c = ""

			if ~[".scss",".sass"].indexOf path.extname(f)
				try
					data = sass.renderSync {data}
					c = " (compiled)"
				catch e
					data = "/* Sass error: #{e} */"

			[
				"/* @begin #{f}#{c} */"
				data
				"/* @end #{f}#{c} */"
				""
			].join("\n\n")
		).join("")

		console.log "Writing", path.join(global.dex_cache_dir, "#{hostname}.css")
		fs.writeFile path.join(global.dex_cache_dir, "#{hostname}.css"), cssData

	jsonData = JSON.stringify({
		metadata
		site_available:   modulesByHostname.available[hostname]
		site_enabled:     modulesByHostname.enabled[hostname]
		global_available: modulesByHostname.available["global"]
		global_enabled:   modulesByHostname.enabled["global"]
	}, null, "  ")

	console.log "Writing", path.join(global.dex_cache_dir, "#{hostname}.json")
	fs.writeFile path.join(global.dex_cache_dir, "#{hostname}.json"), jsonData
	console.log "\n"