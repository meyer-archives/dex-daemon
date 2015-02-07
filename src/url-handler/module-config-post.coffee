module.exports = (request, response, next) ->
	body = "module-config-update (params: #{request.params.join ", "})"

	response.send 200, body
	console.log body

	do next