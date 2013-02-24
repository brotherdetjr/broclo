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

	wrapFunc = (func, config) -> ->
		try
			func.apply config.src, arguments
		catch error
			if error instanceof exports.ConstraintError
				config.resolveConflict?.call config.src,
					method: func
					args: arguments
					error: error
			else
				throw error

	exports.wrap = (config) ->
			proxy = {}
			for key, value of config.src
				if key != 'constructor' and value instanceof Function
					proxy[key] = wrapFunc value, config
			proxy

)(if exports? then exports else @utils = {})
