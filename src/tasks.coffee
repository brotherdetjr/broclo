((exports, EventEmitter, utils) ->

	class Repo
		constructor: ->
			@types = {}
			@groups = {}

		addType: (type) ->
			if @getTypeById(type.id)?
				throw new ConstraintError
			@types[type.id] = type
			@emit 'addType', type
			type

		removeTypeById: (id) ->
			type = @getTypeById id
			if not type? or @getGroupByTypeId(id)?
				throw new ConstraintError
			delete @types[id]
			@emit 'removeType', type
			type

		getTypeById: (id) -> @types[id]

		getTypeCount: -> utils.countKeys @types

		addGroup: (group) ->
			if @getGroupByTypeId(group.type.id)? or not @getTypeById(group.type.id)?
				throw new ConstraintError
			@groups[group.type.id] = group
			group.repo = @
			group.type = @getTypeById group.type.id
			@emit 'addGroup', group
			group

		removeGroupByTypeId: (id) ->
			group = @getGroupByTypeId id
			if not group? or group.getTaskCount() != 0
				throw new ConstraintError
			delete @groups[id]
			group.repo = undefined
			@emit 'removeGroup', group
			group

		getGroupByTypeId: (id) -> @groups[id]

		getGroupCount: -> utils.countKeys @groups

	utils.mixin Repo, EventEmitter

	class ConstraintError extends Error
		constructor: ->

	# Relates to Type as 0..1 to 1
	class Group
		constructor: (@type) ->
			@tasks = {}
			@repo = undefined

		addTask: (task) ->
			if @getTaskById(task.id)? or task.type.id != @type.id
				throw new ConstraintError
			@tasks[task.id] = task
			task.type = @type
			@emit 'addTask', task
			task

		removeTaskById: (id) ->
			task = @getTaskById id
			if not task? then throw new ConstraintError
			delete @tasks[id]
			@emit 'removeTask', task
			task

		getTaskById: (id) -> @tasks[id]

		getTaskCount: -> utils.countKeys @tasks

		@asGroup: (type) -> new Group type

	utils.mixin Group, EventEmitter

	class Type
		constructor: (@id, @sampleInput) ->

		@asType: (id, sampleInput) -> new Type id, sampleInput

	class Task
		# Task's id must be unique through all the Repo
		# Relates to Type as 0..N to 1
		constructor: (@id, @type, @since = new Date) ->

		@asTask: (id, type, since) -> new Task id, type, since

	class Externalizer
		constructor: ->

		@repo: ->
			export: (repo) ->

			import: (external) ->

	exports.Repo = Repo
	exports.ConstraintError = ConstraintError
	exports.Group = Group
	exports.Type = Type
	exports.Task = Task
	exports.Externalizer = Externalizer
)(
	(if exports? then exports else @tasks = {}),
	(if @EventEmitter? then @EventEmitter else require('events').EventEmitter),
	(if @utils? then @utils else require './utils')
)
