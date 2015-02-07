module.exports = (request, response, next) ->
	body = "module-edit (params: #{request.params.join ", "})"

	response.send 200, body
	console.log body

	do next