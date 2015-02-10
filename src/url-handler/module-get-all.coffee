_ = require "lodash"
fs = require "fs-extra"
path = require "path"
glob = require "glob"
urlUtils = require "../utils/url"

sass = require "node-sass"
coffee = require "coffee-script"

configUtils = require "../utils/config"
globtions = _.extend configUtils.globtions, nodir: true

uggs = require "uglify-js"
uglifyOptions = fromString: true

cssmin = require "cssmin"


buildFile = (f) ->
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

			#{cssmin data}

			/* @end #{f}#{c} */
			"""

		when ".js", ".coffee"
			"""
			console.group("#{f}#{c}");

			#{uggs.minify(data, uglifyOptions).code}

			console.groupEnd();
			"""

		else
			console.error "Unsupported filetype: #{ext}"
			return ""


module.exports = (request, response, next) ->
	config = configUtils.getConfig()

	{
		metadata
		modulesByHostname
	} = config

	console.log "Get all module data? NOOOOOOO. YESSSS"

	moduleDataByFilename = {}

	###

	moduleData.js[global] = [
		enabled
		global
		files
	]

	moduleData.js[dribbble.com] = [
		"dribbble.com/setup.coffee"
	]

	js = [].concat moduleData[global].js

	if moduleData[hostname]?.js
		js = js.concat moduleData[hostname].js

	return js.join("\n\n")

	###

	moduleData = {}

	process.chdir global.dex_file_dir

	mods = _.extend(
		_.pick(modulesByHostname.available, "global")
		{utilities: modulesByHostname.utilities}
		_.omit(modulesByHostname.available, "global")
	)

	_.each mods, (hostModules, hostname) ->
		console.log "wow", hostModules
		if hostname == "utilities"
			hostname = []

		_.each [].concat(hostname, hostModules), (modulePath) ->
			obj = {
				jsFiles: []
				js: null
				cssFiles: []
				css: null
			}

			jsFiles = glob.sync("#{modulePath}/*.{js,coffee}", globtions)
			cssFiles = glob.sync("#{modulePath}/*.{css,scss,sass}", globtions)

			if jsFiles.length > 0
				obj.js = jsFiles.map(buildFile).join("\n\n\n")
				obj.jsFiles = jsFiles

			if cssFiles.length > 0
				obj.css = cssFiles.map(buildFile).join("\n\n\n")
				obj.cssFiles = cssFiles

			if (cssFiles.length + jsFiles.length) > 0
				moduleData[modulePath] = obj


	response.send 200, {
		modulesByHostname
		moduleData
		metadata
	}

	next()