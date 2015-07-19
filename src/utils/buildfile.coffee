fs = require "fs-extra"
path = require "path"

sass = require "node-sass"
coffee = require "coffee-script"

logger = require "./log"

module.exports = (f) ->
	filePath = path.join(global.dex_file_dir, f)
	data = fs.readFileSync filePath, encoding: "utf8"
	pathParts = path.parse(filePath)

	switch pathParts.ext
		when ".scss", ".sass"
			try
				data = sass.renderSync({
					data: data
					includePaths: [
						# Good option: relative paths
						pathParts.dir
						# Better option: keep utils in /utilities
						path.join(global.dex_file_dir, "utilities")
					]
				}).css
			catch e
				logger.error "Sass compile error".red
				logger.error "#{e}"
				data = "/* Sass compile error: #{e} */"

		when ".coffee"
			try
				data = coffee.compile(data)
			catch e
				logger.error error: e, "CoffeeScript compile error: #{path.join global.dex_file_dir, f}:#{e.location.first_line+1}:#{e.location.first_column+1}"
				data = "console.error(\"CoffeeScript compile error: #{e.toString()}\");"

	switch pathParts.ext
		when ".css", ".scss", ".sass"
			"""
			/* @begin #{f} */

			#{data}

			/* @end #{f} */
			"""

		when ".js", ".coffee"
			"""
			console.group("#{f}");

			#{data}

			console.groupEnd();
			"""

		else
			logger.error "Unsupported filetype: #{pathParts.ext}"
			false