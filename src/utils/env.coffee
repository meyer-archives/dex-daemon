getRequiredVar = (varName) ->
	unless process.env[varName]?
		throw new Error("Enviromental variable `#{varName}` is not set.")
	process.env[varName]

module.exports.getRequiredVar = getRequiredVar