"use strict"

module.exports = (grunt) ->
	grunt.initConfig

		nodemon:
			dexSrc:
				script: "./app.coffee"

				options:
					args: []
					nodeArgs: []

					env:
						DEX_PORT: "3131"
						DEX_CACHE_DIR: "/Users/meyer/"
						DEX_FILE_DIR: "/Users/meyer/Repositories/dexfiles"
						DEX_CONFIG_DIR: "/Users/meyer/"

					callback: (nodemon) ->
						nodemon.on "log", (e) ->
							console.log "#{e.colour}"

					ignore: [
						"node_modules/**"
						"public/**"
					]
					ext: "coffee"
					watch: ["app.coffee", "./src"]
					# delay: 1000
					# logConcurrentOutput: true

		coffeelint:
			dexSrc:
				files: [{
					src: ["src/*.coffee", "app.coffee"]
				}]

				options:
					configFile: "coffeelint.json"

	grunt.loadNpmTasks "grunt-nodemon"
	grunt.loadNpmTasks "grunt-coffeelint"

	grunt.registerTask "default", ["nodemon"]