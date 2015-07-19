colors = require "colors"
requestEndTimeout = false

module.exports = (request, response, e) ->
	clearTimeout requestEndTimeout

	statusCode = "#{response.statusCode}"

	switch statusCode.slice(0,2)
		when "20"
			statusCode = statusCode.green
		when "30"
			statusCode = statusCode.yellow
		when "50"
			statusCode = statusCode.red


	now = new Date

	log = [
		[
			"["
			"#{now.toString().split(" ")[4]}".yellow
			"."
			"#{(now.getMilliseconds() + 10000).toString().slice(1)}".yellow
			"]"
		].join("")
		# "#{request.method}"
		"#{statusCode}"
		"#{request.originalURL}"
	]

	if ~[301, 302].indexOf response.statusCode
		log.push "-->"
		log.push response.getHeader("Location")

	console.log log.join(" ")

	requestEndTimeout = setTimeout(() ->
		console.log "=================".grey
	, 500)

	return