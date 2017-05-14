createConditional = (conditional, validators)->
	return {
		conditional
		validators
		type: "MarioConditional"
	}


module.exports = createConditional