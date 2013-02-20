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

)(if exports? then exports else @utils = {})
