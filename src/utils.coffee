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

	exports.resolveWrapper = (func, name, self, resolver) -> ->
		try
			func.apply self, arguments
		catch error
			if error instanceof exports.ConstraintError
				resolver?.call self,
					method: func
					args: arguments
					error: error
			else
				throw error

	exports.wrap = (obj, wrapper, config, filter = -> true) ->
		proxy = {}
		for key, value of obj
			if key != 'constructor' and value instanceof Function and
			filter key, value, obj
				proxy[key] = wrapper value, key, obj, config
		proxy

)(if exports? then exports else @utils = {})
