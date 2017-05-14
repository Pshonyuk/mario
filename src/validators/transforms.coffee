_ = require("./../utils/utils-library.coffee").require()
REG_EXP = require "../constants/regexp.coffee"
storage = Object.create null



MarioTransform = (func, name)->
	@func = func 
	@name = name
	return

MarioTransform::type = "MarioTransforms"


###*
 * [extendFilters розширює трансформації Mario.transforms]
 * @param  {[string]} name [назва трансформації]
 * @param  {[function]} f  [обробник]
 * @return {[null]}        []
###
extendTransforms = (name, f)->
	if !_.isObject(name)
		(obj = {})[name] = f
	else
		obj = name

	for own key, func of obj
		if _.has(storage, key)
			console.warn "MarioTransforms has #{key}"
		else if _.isFunction(func)
			storage[key] = new MarioTransform func, key
	return



extendTransforms {
	toNumber: (val)->
		val = if _.isString(val) then parseFloat(val, 10) else +val
		return null if _.isNaN(val)
		return val

	toIntNumber: (val)->
		val = if _.isString(val) then parseInt(val, 10) else +val
		return null if _.isNaN(val)
		return val.toFixed(0)

	floorNumber:(val)->
		val = if _.isString(val) then parseInt(val, 10) else +val
		return null if _.isNaN(val)
		return Math.floor val

	ceilNumber:(val)->
		val = if _.isString(val) then parseInt(val, 10) else +val
		return null if _.isNaN(val)
		return Math.ceil val

	toString: (val)->
		return "" + val

	toBoolean: (val)->
		return !!val


	toDigital: (val)->
		val = "" + val
		return val.replace REG_EXP.NOT_DIGITAL, ""
}



transforms = ->
	return transforms.get.apply null, arguments


transforms.get = (name, args...)->
	throw new Error("Undefined MarioTransform.#{name}") if !storage[name]
	if args.length
		func = storage[name].func.apply null, args
		throw new Error("MarioTransform return non-function.") if !_.isFunction(func)
		return new MarioFilter func, name
	return storage[name]


transforms.add = (name, func)->
	extendFilters name, func
	return @


transforms.extend = ->
	extendFilters.apply null, arguments
	return @


transforms.remove = (name)->
	delete storage[name]
	return @



module.exports = transforms