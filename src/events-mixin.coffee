_ = require("./utils/utils-library.coffee").require()
nativeDefProp = Object.defineProperty
REG_EXP_SPACES = /\s/g



mixin = {
	on: (type, callback)->
		if type && typeof callback is "function"
			type = type.replace REG_EXP_SPACES, ""
			@_eStack[type] || (@_eStack[type] = [])
			@_eStack[type].push {
				"callback"	: callback
			}
		return @


	one: (type, callback)->
		if type && typeof callback is "function"
			type = type.replace REG_EXP_SPACES, ""
			@_eStack[type] || (@_eStack[type] = [])
			@_eStack[type].push {
				"callback"	: callback
				"one"		: true
			}
		return @


	off: (type, callback)->
		if type
			type = type.replace REG_EXP_SPACES, ""
		else
			return @
		handlers = @_eStack[type]
		if handlers
			if !_.isFunction(callback)
				handlers.length = 0
				return @
			i = 0
			while i < handlers.length
				handler = handlers[i]
				handlers.splice(i, 1) if handler.callback is callback
		return @


	trigger: (type, args...)->
		if type
			type = type.replace REG_EXP_SPACES, ""
		else
			return @
		handlers = @_eStack[type]
		self = @_self || @
		if handlers
			i = 0
			while i < handlers.length
				handler = handlers[i++]
				handler.callback.apply self, args
				handlers.splice(i - 1, 1) if handler.one
		return @
}



module.exports = (obj)->
	if _.isObject(obj)
		_.extend obj, mixin
		if !_.isObject(obj._eStack)
				nativeDefProp obj, "_eStack", {
					value:  Object.create null
				}
	return obj