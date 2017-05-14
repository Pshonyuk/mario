_ = require("./../utils/utils-library.coffee").require()
ArrayProto = Array::
storage = Object.create null


MarioFilter = (func, name)->
	@func = func
	@name = name
	return

MarioFilter::type = "MarioFilters"


###*
 * [extendFilters розширює фільрти Mario.filters]
 * @param  {[string]} name [назва фільтра]
 * @param  {[function]} f  [обробник]
 * @return {[null]}        []
###
extendFilters = (name, f)->
	if !_.isObject(name)
		(obj = {})[name] = f
	else
		obj = name

	for own key, func of obj
		if _.has(storage, key)
			console.warn "MarioFilters has #{key}"
		else if _.isFunction(func)
			storage[key] = new MarioFilter func, key
	return null



extendFilters {
	isNull: (val)->
		return val is null

	notNull: (val)->
		return val isnt null

	isUndefined: (val)->
		return _.isUndefined(val)

	notUndefined: (val)->
		return !@isUndefined(val)

	isBoolean: (val)->
		return _.isBoolean(val)

	notBoolean: (val)->
		return !isBoolean(val)

	isNumber: (val)->
		return _.isNumber(val)

	notNumber: (val)->
		return !@isNumber(val)

	isFinite: (val)->
		return _.isFinite(val)

	notFinite: (val)->
		return !@isFinite(val)

	isNaN: (val)->
		return _.isNaN(val)

	notNaN: (val)->
		return !@isNaN(val)

	isString: (val)->
		return _.isString(val)

	notString: (val)->
		return !@isString(val)

	isObject: (val)->
		return _.isObject(val)

	notObject: (val)->
		return !@isObject(val)

	isArray: (val)->
		return _.isArray(val)

	notArray: (val)->
		return !isArray(val)

	isFunction: (val)->
		return _.isFunction(val)

	notFunction: (val)->
		return !isFunction(val)

	isDateObject: (val)->
		return _.isDate(val)

	notDateObject: (val)->
		return !isDate(val)

	isRegexp: (val)->
		return _.isRegexp(val)

	notRegexp: (val)->
		return !isRegexp(val)

	range: (min = 0, max = Infinity)->
		min = +min
		max = +max

		return (val)->
			val = +val
			return _.isNumber(val) && val >= min && val <= max

	outsideRange: (min = 0, max = Infinity)->
		min = +min
		max = +max
		return (val)->
			return _.isNumber(val) && (val < min || val > max)

	anyMatch: (args)->
		args = ArrayProto.slice.call(arguments) if !_.isArray(args)
		return (val)->
			return args.indexOf(val) isnt -1

	notMatch: (args)->
		args = ArrayProto.slice.call(arguments) if !_.isArray(args)
		return (val)->
			return args.indexOf(val) is -1

	value: (defVal)->
		return (val)->
			return val is defVal


	notValue: (defVal)->
		return (val)->
			return val isnt defVal


	anyFilterMatch: (funcs)->
		funcs = [funcs] if !_.isArray(funcs)
		return (val)->
			for f in funcs
				return true if f.func(val)
			return false


	notFilterMatch: (funcs)->
		funcs = [funcs] if !_.isArray(funcs)
		return (val)->
			for f in funcs
				return true if !f.func(val)
			return false
}



filters = (name)->
	return filters.get.apply null, arguments


filters.get = (name, args...)->
	throw new Error("Undefined MarioFilter.#{name}") if !storage[name]
	if args.length
		func = storage[name].func.apply null, args
		throw new Error("MarioFilter return non-function.") if !_.isFunction(func)
		return new MarioFilter func, name
	return storage[name]


filters.add = (name, func)->
	extendFilters name, func
	return @


filters.extend = ->
	extendFilters.apply null, arguments
	return @


filters.remove = (name)->
	delete storage[name]
	return @



module.exports = filters