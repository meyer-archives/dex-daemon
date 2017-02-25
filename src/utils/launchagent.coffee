###
fs = require "fs"
plist = require "plist"
_ = require "lodash"

# Ripped from node-mac:
# https://github.com/coreybutler/node-mac/blob/433df4fa673d86827d0ae224d51eb5d4eaac91c9/lib/daemon.js

generatePlist = (data) ->


	tpl =
		Label: data.label
		ProgramArguments: data.args
		RunAtLoad: true
		KeepAlive: false
		WorkingDirectory: me.cwd
		StandardOutPath: me.outlog
		StandardErrorPath: me.errlog


	fileContents

module.exports.generate = generatePlist
###