pkg = require "../../package.json"
restify = require "restify"
bunyan = require "bunyan"

module.exports = bunyan.createLogger
    name: pkg.name,
    serializers: restify.bunyan.serializers