###
 *Compatibility
 	Firefox 4.0
 	Chrome 6
 	IE 9
 	Opera 12
 	Safari 5.1
###


do (root = window, factory = (_)->
	"use strict"

	nativeDefProps = Object.defineProperties
	nativeDefProp = Object.defineProperty
	nativeFreeze = Object.freeze
	throw "This browser is not supported" if !nativeFreeze || !nativeDefProps

	require("./utils/utils-library.coffee").define _

	eMixin = require "./events-mixin.coffee"
	errors = require "./errors.coffee"
	MARIO_DEFAULT_ARGS = require "./constants/default-arguments.coffee"
	accessors = require "./accessors.coffee"
	storage = Object.create null


	###*
	 * [Mario description]
	 * @param {[string]} nameMarioScheme [назва схеми]
	 * @param {[object]} obj      	     [опис схеми]
	###
	Mario = (nameMarioScheme, obj)->
		_.isObject(obj) || obj = {}
		mixinObj = Object.create null
		keys = []

		for own key, optionParams of obj
			params = Object.create null
			if !_.isObject(optionParams)
				value = optionParams
				(optionParams = {}).value = value

			_.defaults optionParams, MARIO_DEFAULT_ARGS

			#валідація даних (залежності та місця їх вставки, дані функцій фільтрації і трансформації, тип елемента та характер співставлення значень)
			depsInGetter = !!optionParams.depsInGetter
			depsInSetter = !!optionParams.depsInSetter
			isDeepEqual = !!optionParams.deepEqual
			isConstant = !!optionParams.constantValue
			validators = createValidators optionParams.validators
			deps = createDeps optionParams.deps

			#об'єкт, який буде присвоєно прототипу конструктора елемента, містить аксесори
			cOptions = Object.create null
			cOptions.get = accessors.createGetter optionParams.getter, key, (depsInGetter && deps)
			if !isConstant || !(_.isObject(optionParams.react) && _.isFunction(optionParams.react.compute) && !isConstant)
				cOptions.set = accessors.createSetter(optionParams.setter, key, validators, (depsInSetter && deps), isDeepEqual) if !isConstant

			#присвоєння валідованих даних об'єкту, для збереження в storage
			params.depsInConstructor = !!optionParams.depsInConstructor
			params.userConstructor = if _.isFunction(optionParams.construct) then optionParams.construct else null
			params.isConstant = isConstant
			params.value = optionParams.value
			params.deps = deps

			#створюється аксесор для обчислювального поля
			if _.isObject(optionParams.react) && _.isFunction(optionParams.react.compute) && !isConstant
				fields = optionParams.react.fields
				if _.isArray(fields)
					params.computeFields = fields
				else if _.isString(fields)
					params.computeFields = [fields]
				if params.computeFields
					params.computeFunc = accessors.createComputeField optionParams.react.compute, key

			#створення конструктора елемента
			params.Constructor = createPropertyConstructor cOptions
			keys.push key
			mixinObj[key] = params

		###дані схеми заносяться в storage, формат збереження 
		 *keys - масив із назв елементів (призначаний для оптимізації визначення залежностей)
		 *mixinObj - сама схема із валідованими даними (схема передана користувачем не зберігається)
		###
		storage[nameMarioScheme] = {keys, mixinObj}
		return Mario



	Mario.filters = require "./validators/filters.coffee"
	Mario.transforms = require "./validators/transforms.coffee"


	###*
	 * [mixin - ініціалізує MarioScheme та добавляє функціонал подій до об'єкта]
	 * @param  {[string]} nameMarioScheme [назва MarioScheme, у разі выдсутності схеми буде сформовано помилку типу Undefined:MarioScheme]
	 * @param  {[*]} obj       	  	  	  [об'єкт на якому буде ініціюватися схема, якщо аргумент не об'єкт, то буде створено і повернено новий]
	 * @param  {[object,null]} args 	  [значення елеентів,  (будуть задіяні у схемі, як дефолтні значення)]
	 * @return {[object]}           	  [повертається завжди об'єкт із примісом схеми і подій]
	###
	Mario.mixin = (nameMarioScheme, obj, args)->
		throw new errors.undefinedArg if !nameMarioScheme || !storage[nameMarioScheme]

		#схема (MarioScheme)
		mixinObj = storage[nameMarioScheme].mixinObj
		#міститеме назви елементів, які уже сконструйовано
		initRegister = {}
		#міститеме назви елементів, побудова яких призупинена для обчислення залежностей
		recRegister = {}


		_.isObject(obj) || (obj = {})
		_.isObject(args) || args = Object.create(null)

		#створення об'єкт для збереження та контролю елементів
		if !_.isObject(obj._mario)
			nativeDefProp obj, "_mario", {
				value:  Object.create null
			}
		#приміс подій
		eMixin obj

		#"позика" методів
		obj.get = getValue
		obj.set = setValue
		obj.getDefault = getDefaultValue mixinObj
		marioSpace = obj._mario

		#функція приймає масив назв елементів, які потрібно сконструювати
		#якщо в елемента немає залежностей то він відразу ж створюється (createProperty) та реєструється в initRegister,
		#інакше здійснюється реєстрація елемента в recRegister та рекурсивний виклик eachMixin із масивом залежностей 
		eachMixin = (depsList)->
			for key in depsList
				isCreated = _.has initRegister, key
				throw "Circular structure in dependens." if _.has(recRegister, key) && !isCreated
				optionParams = mixinObj[key]
				continue if !optionParams || isCreated
				if optionParams.deps
					recRegister[key] = true
					eachMixin optionParams.deps
				createProperty optionParams, marioSpace, args, key, obj
				initRegister[key] = true

		eachMixin storage[nameMarioScheme].keys
		return obj


	###*
	 * [eventsMixin - ініціює роботу з подіями]
	 * @param  {[object]} obj [об'єкт в який буде "підмішано" функціонал подій]
	 * @return {[object]}     [вхідний об'єкт, розширений eventsMixin]
	###
	Mario.eventsMixin = (obj)->
		eMixin obj
		return Mario


	###*
	 * [destroy вилучає схему]
	 * @param  {[string]} name [назва сехми]
	 * @return {[Object]}      [Mario]
	###
	Mario.destroy = (name)->
		delete storage[name]
		return Mario


	###*
	 * [destroyAll вилучає всі схеми із сховища]
	 * @return {[object]} [Mario]
	###
	Mario.destroyAll = ->
		storage = Object.create null
		return Mario



	###*
	 * [getValue функція "позичається" для gettera, obj.get() = (obj.get = getValue)()]
	 * @param  {[string]} name    [назва елемента]
	 * @param  {[type]} args...   [аргументи]
	 * @return {[type]}           [значення елемента або null уразі його відсутності]
	###
	getValue = (name, args...)->
		return if @_mario && @_mario[name] && @_mario[name].get then @_mario[name].get(args...) else null


	###*
	 * [setValue функція "позичається" для settera, obj.set() = (obj.set = setValue)()]
	 * @param  {[string]} name    [назва елемента]
	 * @param  {[type]} args...   [аргументи]
	 * @return {[object]}         [поточний об'єкт]
	###
	setValue = (name, args...)->
		@_mario[name].set(args...) if @_mario[name] && @_mario[name].set
		return @


	###*
	 * [setValue генератор функції для повернення дефолтного значення, застосовується до схеми]
	 * @param  {[string]} name    [схема]
	 * @return {[function]}       [повертає функцію, яка по назві елемента віддає його дефолтне значення (obj.getDefault(name))]
	###
	getDefaultValue = (mixinObj)->
		return (name)->
			return mixinObj[name].value if mixinObj[name]
			return null



	###*
	 * [createPropertyConstructor генератор конструтора для елемента схеми (екземпляри к. знаходяться в захищеному полі _mario)]
	 * @param  {[object]} params 	 [об'єкт]
	 * @return {[function]}        	 [конструктор елемента схеми]
	###
	createPropertyConstructor = (params)->
		Property = (parentObj, isConstant)->
			nativeDefProps @, {
				"_self":
					value: parentObj
				"_value":
					confirugable: isConstant
					writable: true
			}
			return
		Property.prototype = params
		return Property



	###*
	 * [createValidators створює верифікований масив для управління підготовкою даних]
	 * @param  {[array,string]} obj [дані про функції фільтрації і трансформації]
	 * @return {[array]}            [масив із функцією-обробником, назвою і його типом, та аргументами, які будуть передаватися при делегації подій]
	###
	createValidators = (obj)->
		result = []
		obj = [obj] if !_.isArray(obj)
		for data in obj
			if _.isObject(data) && _.isFunction(data.func)
				result.push {
					func: data.func
					type: data.type
					name: data.name
					args: []
				}
			else if _.isArray(data) && _.isObject(data[0]) && _.isFunction(data[0].func)
				result.push {
					func: data.func
					type: data.type
					name: data.name
					args: data.slice 1
				}
		return if result.length then result else null



	###*
	 * [createDeps створює масив залежностей]
	 * @param  {[string/array]} deps [залежності]
	 * @return {[type]}     		 [масив залежностей]
	###
	createDeps = (deps)->
		result = []
		if _.isString(deps)
			result.push deps
		else if _.isArray(deps)
			for dep in deps
				result.push(dep) if _.isString(dep)
		return if result.length then result else null



	###*
	 * [createComputeField створення обчислювального поля]
	 * @param  {[function]} cfu     [функція, яка передана із схеми (accesseor)]
	 * @param  {[array]}  cfi       [список полів (computeFields)]
	 * @param  {[object]} obj       [об'єкт елемента схеми]
	 * @param  {[string]} key       [назва елемента]
	 * @param  {[object]} parentObj [об'єкт до якого "примішується" схема]
	 * @return {[null]}           	[description]
	###
	createComputeField = (cfu, cfi, obj, key, parentObj)->
		if !_.isFunction(parentObj.on)
			throw new Error "no event processing function on the root element"

		#прив'язується функція із схеми до поточного елемента із карінгом залежностей(полів) та об'єкт для контролю стану 
		cfu = cfu.bind obj[key], cfi, {status: false, fields: []}

		#якщо елемент знаходяться в поточному об'єкті або зовнішньому то
		#на даний об'єкт "вішаються" подія "change", якщо елемент ще не
		#створено, то додково "вішаються" одноразова подія "init"
		for field in cfi
			if _.isString(field) && field isnt key
				if !parentObj._mario[field]
					parentObj.one "init:#{field}", cfu
				parentObj.on "change:#{field}", cfu
			else if _.isArray(field)
				pObj = field[0]
				prop = field[1]
				throw new Error "no event processing function on the root element" if !_.isObject(pObj) || !_.isFunction(pObj.on)
				if !pObj._mario[field]
					pObj.one "init:#{field}", cfu
				pObj.on "change:#{prop}", cfu
			else
				throw new Error "can't create a calculated field with fields"

		#запуск обчислення поля
		cfu()
		return null



	###*
	 * [createProperty ініціює елемент схеми (псевдо конструктор)]
	 * @param  {[object]} optionParams [властивості елемента (в кінцевому вигляді)]
	 * @param  {[object]} obj          [marioSpace (_mario - об'єкт, в якому зберігаються всі елементи схеми)]
	 * @param  {[object]} args         [дефолтні аргументи  (у разі відсутності значення в схемі)]
	 * @param  {[string]} key          [назва елемента]
	 * @param  {[object]} parentObj    [об'єкт до якого "примішується" схема]
	 * @return {[null]}                [description]
	###
	createProperty = (optionParams, obj, args, key, parentObj)->
		value = if _.isUndefined(args[key]) then optionParams.value else args[key]
		obj[key] = new optionParams.Constructor parentObj

		#конструюється функція, яка відповідатиме за контроль обчислювальних полів
		if optionParams.computeFunc
			createComputeField optionParams.computeFunc, optionParams.computeFields, obj, key, parentObj

		#запускається конструктор користувача, якщо присутній
		#в аргументи передабться значення залежних опцій (depsValues), значення в схемі і значення, з яким була ініційована схема
		#depsValues визначаються, якщо depsInConstructor = true
		if optionParams.userConstructor
			depsValues = []
			if optionParams.deps && optionParams.depsInConstructor
				for dep in optionParams.deps
					prop = parentObj._mario[dep]
					depsValues.push if prop then (if prop.get then prop.get() else prop._value) else undefined
			value = optionParams.userConstructor.call parentObj, depsValues..., optionParams.value, args[key]

		#для обчислювальних полів, опції за замовчування не створюються
		#при константах встановлюється значення із схеми або конструктора
		#інакше задається значення через setter
		if !optionParams.computeFunc
			if optionParams.isConstant
				obj[key]._value = if optionParams.userConstructor then value else optionParams.value
				nativeFreeze obj[key]
			else
				obj[key].set(value) if obj[key].set

		parentObj.trigger "init:#{key}", obj[key].get()
		return null

	return Mario
)->
	"use strict"
	if typeof define is "function" && define.amd
		define ["underscore"], factory
	else
		old = root.Mario
		root.Mario = factory _

		root.Mario.noConflict = ->
			obj = root.Mario
			root.Mario = old
			return obj
	return