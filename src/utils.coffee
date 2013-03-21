((exports) ->

	s4 = -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1

	exports.capitalize = (string) ->
		string.charAt(0).toUpperCase() + string.slice 1

	exports.guid = ->
		s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()

	exports.countKeys = (obj) ->
		result = 0
		for key, value of obj
			result++
		result

	exports.NotImplementedError = class extends Error
		constructor: ->

	exports.ConstraintError = class ConstraintError extends Error
		constructor: ->

	exports.proxy = (obj, methodWrapper, filter = -> true) ->
		proxy = {}
		basicFilter = (key, value) ->
			key != 'constructor' and value instanceof Function
		for key, value of obj
			if basicFilter(key, value) and filter(key, value, obj)
				proxy[key] = methodWrapper value, key, obj
		proxy

	exports.holder = (obj) ->
		proxy = exports.proxy obj, (func, name, obj) -> ->
			proxy._content[name].apply proxy._content, arguments
		proxy.hold = (obj) -> proxy._content = obj
		proxy.hold obj
		proxy

	exports.resolvingProxy = (obj, resolver) ->
		exports.proxy obj, (func, name, obj) -> ->
			try
				func.apply obj, arguments
			catch error
				if error instanceof exports.ConstraintError
					resolver.call obj,
						method: func
						args: arguments
						error: error
				else
					throw error

	exports.eventProxy = (obj, eventEmitter) ->
		exports.proxy obj, (func, name, obj) -> ->
			eventEmitter.emit 'before' + exports.capitalize(name),
				obj: obj
				args: arguments
			value = undefined
			try
				value = func.apply obj, arguments
			catch error
				eventEmitter.emit 'throwed' + exports.capitalize(name),
					obj: obj
					args: arguments
					error: error
				throw error
			eventEmitter.emit 'after' + exports.capitalize(name),
				obj: obj
				args: arguments
				value: value

	exports.nextTick = (func) ->
		if process?
			process.nextTick func
		else
			setTimeout func, 0

	###
	Special helper method for Mocha+Sinon.JS spies
	
	Usage:
	it 'should blah blah', do ->
		callback = sinon.spy()
		someAsyncService.doMyDay 42, callback
		utils.eventually ->
			spy.calledOnce.should.be.true
			...

	Notice *do* keyword after it '...'
	Also eventually() call should be the last expression (implicitly returned).
	###
	exports.eventually = (func) -> (done) ->
		setTimeout ->
			func.call @
			done()
		, @_runnable._timeout / 20

)(if exports? then exports else @utils = {})
