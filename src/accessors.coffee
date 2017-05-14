_ = require("./utils/utils-library.coffee").require()


###*
 * [createComputeField створює функцію для опрацювання обчислювального поля]
 * @param  {function} userFunc [функція-обробник (react.compute)]
 * @param  {string} key        [назва елемента]
 * @return {function}          [повернена функція зберігається в схемі і використовується при подальшій ініцілізації схеми]
###
createComputeField = (userFunc, key)->
	return (fieldsList,  initData)->
		oldValue = @_value
		parentObj = @_self
		values = []
		initFields = initData.fields

		###
		 *Здійснюється обхід всіх полів.
		 *В залежності в якому об'єкті поле (поточному чи зовнішньому) визначається чи поле уже ініційоване, якщо ні, то вихід.
		 *Всі ініційовані поля додаються масив у initData.fields (initData, fieldsList - змінні отримані каррінгом)
		 *Якщо всі поля присутні, то дія перевірки більше не повторяється, і значенні полів отримуються
		 *обходом initData.fields.
		###
		if !initData.status
			for field, i in fieldsList
				if _.isString(field)
					prop = parentObj._mario[field]
					if prop
						initFields[i] = prop
					else
						return @
				else if _.isArray(field)
					prop = field[0]._mario && field[0]._mario[field[1]]
					if prop
						initFields[i] = prop
					else
						return @
			initData.status = true

		for field in initFields
			values.push field.get()

		values.push oldValue
		newValue = userFunc.apply parentObj, values
		@_value = newValue

		parentObj.trigger "change:#{key}", newValue, oldValue
		return @


###*
 * [createGetter створює аксесор доступу]
 * @param  {function,null} userGetter [аксесор користувача]
 * @param  {string} key       		  [назва елемента]
 * @param  {[array,null]} deps        [залежності (передаються при depsInGetter === true)]
 * @return {function}           	  [функція яка буде викликатися при доступі до елемента (зберігається в схемі)]
###
createGetter = (userGetter, key, deps)->
	return (args...)->
		parentObj = @_self

		##викликається getter користувача (при необхідності із значеннями залежностей)
		if userGetter
			depsValues = []
			if deps
				for dep in deps
					prop = parentObj._mario[dep]
					depsValues.push if prop then prop.get() else undefined
			value = userGetter.apply parentObj, [@_value, depsValues..., args...]
		else
			value = @_value

		return value



###*
 * [createSetter створює аксесор зміни]
 * @param  {function,null}  userSetter  [аксесор користувача]
 * @param  {string}  key         				[назва елемента]
 * @param  {[array, null]}  validators 	[дані про функції фільтрації і трансформації]
 * @param  {[array,null]}  deps     		[залежності (передаються при depsInSetter === true)]
 * @param  {Boolean} isDeepEqual 				[варіант порівняння старого і нового значення (deepEqaul = true)]
 * @return {function}               		[функція яка буде викликатися і керувати зміною елемента (зберігається в схемі)]
###
createSetter = (userSetter, key, validators, deps, isDeepEqual)->
	return (newValue, args...)->
		oldValue = @_value
		parentObj = @_self
		isValidation = true

		#в разі необхідності підготовки даних здійснюється обхід масиву із функціями обробки
		#якщо фільтр повертає falsy-значення то закінчується обробка даних і здійснюється вихід із settera 
		#якщо фільтр повертає null/undefinedined то закінчується обробка даних і здійснюється вихід із settera,
		#інакше отримане значення замінює попереднє
		#про помилку при фільтрації чи трансформаціє сигналізує подія "filter" та "transformError" відповідно
		if validators
			originValue = newValue
			for obj in validators
				if obj.type is "MarioFilters"
					if !obj.func.call(parentObj, newValue)
						parentObj.trigger "filter:#{key}", newValue, obj.args... 
						isValidation = false
						break
				else if obj.type is "MarioTransforms"
					newValue = obj.func.call parentObj, newValue
					if !newValue?
						parentObj.trigger "transformError:#{key}", originValue, obj.args... 
						isValidation = false
						break
				else console.error "unknown type of preparation."

			#якщо старе значення і нове рівні, то аксeксор припиняє роботу
			if (isDeepEqual && _.isEqual(originValue, oldValue)) || originValue is oldValue
				return @
			else if !isValidation
				newValue = oldValue
		else
			#якщо старе значення і нове рівні, то аксeксор припиняє роботу
			if (isDeepEqual && _.isEqual(newValue, oldValue)) || newValue is oldValue
				return @

		#викликається setter користувача (при необхідності із значеннями залежностей)
		if userSetter
			depsValues = []
			if deps
				for dep in deps
					prop = parentObj._mario[dep]
					depsValues.push if prop then prop.get() else undefined
			newValue = userSetter.apply parentObj, [newValue, depsValues..., oldValue, args...]

		#присвоєння нового значення та викл події "change"
		@_value = newValue
		parentObj.trigger "change:#{key}", newValue, oldValue, args...
		return @





module.exports = {createGetter, createSetter, createComputeField}