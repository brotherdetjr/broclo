((exports) ->

	extend = (obj, mixin) ->
		obj[name] = method for name, method of mixin
		obj

	exports.mixin = (dest, src) -> extend dest.prototype, src.prototype

	s4 = -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1

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

	exports.delegateResolve = (resolver) -> (func, name, obj) -> ->
		try
			func.apply obj, arguments
		catch error
			if error instanceof exports.ConstraintError
				resolver?.call obj,
					method: func
					args: arguments
					error: error
			else
				throw error

	exports.delegate = -> (func, name, obj) -> ->
		obj._wrapped.apply obj._wrapped, arguments

	exports.wrap = (obj, methodWrapper, filter = -> true) ->
		proxy = {}
		for key, value of obj
			if key != 'constructor' and value instanceof Function and
			filter key, value, obj
				proxy[key] = methodWrapper value, key, obj
		proxy

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
