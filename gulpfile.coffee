fs = require "fs"
gulp = require "gulp"
gutil = require "gulp-util"

_ = require "lodash"
pem = require "pem"
nodemon = require "gulp-nodemon"
coffeelint = require "gulp-coffeelint"

logger = require "./src/utils/log"
sslOptions = require "./ssl/options"

gulp.task "default", ->
	nodemon({
		# nodeArgs: ["--nodejs", "--debug"]
	})

gulp.task "lint", ->
	gulp.src(["app.coffee", "./src/**/*.coffee"])
		.pipe(coffeelint())
		.pipe(coffeelint.reporter())

gulp.task "gimmekeys", (done) ->
	pem.createCertificate sslOptions, (err, keys) ->
		if err
			logger.log "OpenSSL error:", err
			done()
			return

		_.each keys, (keyData, keyName) ->
			switch keyName
				when "certificate"
					ext = "crt"
				when "serviceKey"
					ext = "key"
				# when "csr"
				# when "clientKey"
				else
					return

			fs.writeFileSync "./ssl/server.#{ext}", keyData

		done()