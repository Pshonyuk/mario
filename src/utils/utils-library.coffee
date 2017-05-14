_ = null


module.exports = {
	define:(obj)->
		_ = obj
		return @
	require: ->
		return _
}