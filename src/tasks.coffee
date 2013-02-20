((exports, EventEmitter, utils) ->

	class Repo
		constructor: ->
			@types = {}
			@groups = {}

		addType: (type) ->
			if @getTypeById(type.id)? then throw new DesyncError
			@types[type.id] = type
			@emit 'addType', type
			type

		removeTypeById: (id) ->
			type = @getTypeById(id)
			if not type? then throw new DesyncError
			# TODO check whether correspondent group is empty
			delete @types[id]
			@emit 'removeType', type
			type

		getTypeById: (id) -> @types[id]

		getTypeCount: -> utils.countKeys @types

	utils.mixin Repo, EventEmitter

	class DesyncError
		constructor: ->

	# Relates to Type as 0..1 to 1
	class Group
		constructor: (@type) ->

	class Type
		constructor: (@id, @sampleInput) ->

		@asType: (id, sampleInput) -> new Type id, sampleInput

	class Task
		# Task's id must be unique through all the Repo
		# Relates to Type as 0..N to 1
		# Relates to Group as 0..N to 0..1
		constructor: (@id, @type, @group, @since = new Date) ->

	class Externalizer
		constructor: ->

		@repo: ->
			export: (repo) ->

			import: (external) ->

	exports.Repo = Repo
	exports.DesyncError = DesyncError
	exports.Group = Group
	exports.Type = Type
	exports.Task = Task
	exports.Externalizer = Externalizer
)(
	(if exports? then exports else @tasks = {}),
	(if @EventEmitter? then @EventEmitter else require('events').EventEmitter),
	(if @utils? then @utils else require './utils')
)
