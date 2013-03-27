((exports, utils) ->
	eventProxy = utils.eventProxy
	resolvingProxy = utils.resolvingProxy
	holder = utils.holder
	ConstraintError = utils.ConstraintError
	IllegalArgumentsError = utils.IllegalArgumentsError

	class Repo
		constructor: ->
			@types = {}
			@groups = {}

		getTypes: -> @types

		getGroups: -> @groups

		addType: (type) ->
			if @getTypeById(type.id)?
				throw new ConstraintError
			@types[type.id] = type
			type

		removeTypeById: (id) ->
			type = @getTypeById id
			if not type? or @getGroupByTypeId(id)?
				throw new ConstraintError
			delete @types[id]
			type

		getTypeById: (id) -> @types[id]

		getTypeCount: -> utils.countKeys @types

		addGroup: (group) ->
			if @getGroupByTypeId(group.type.id)? or
			not @getTypeById(group.type.id)? or
			group.getTaskCount() > 0
				throw new ConstraintError
			@groups[group.type.id] = group
			group.repo = @
			group.type = @getTypeById group.type.id
			group

		removeGroupByTypeId: (id) ->
			group = @getGroupByTypeId id
			if not group? or group.getTaskCount() != 0
				throw new ConstraintError
			delete @groups[id]
			group.repo = undefined
			group

		getGroupByTypeId: (id) -> @groups[id]

		getGroupCount: -> utils.countKeys @groups

		getTaskById: (id) ->
			for typeId, group of @groups
				task = group.getTaskById id
				if task? then return task
			null

		addTask: (task) ->
			@getGroupByTypeId(task.type.id).addTask task

		removeTaskById: (id) ->
			@getGroupByTypeId(@getTaskById(id).type.id)
				.removeTaskById id

		getTaskCount: ->
			result = 0
			for typeId, group of @groups
				result += group.getTaskCount()
			result

	# Relates to Type as 0..1 to 1
	class Group
		constructor: (@type) ->
			@tasks = {}
			@repo = undefined

		addTask: (task) ->
			if @getTaskById(task.id)? or
			task.type.id != @type.id or
			@repo?.getTaskById(task.id)?
				throw new ConstraintError
			@tasks[task.id] = task
			task.type = @type
			task

		removeTaskById: (id) ->
			task = @getTaskById id
			if not task? then throw new ConstraintError
			delete @tasks[id]
			task

		getTaskById: (id) -> @tasks[id]

		getTaskCount: -> utils.countKeys @tasks

		@asGroup: (type) -> new Group type

	class Type
		constructor: (@id, @sampleInput) ->

		@asType: (id, sampleInput) -> new Type id, sampleInput

	class Task
		# Task's id must be unique through all the Repo
		# Relates to Type as 0..N to 1
		constructor: (@id, @type, @since = new Date) ->

		@asTask: (id, type, since) -> new Task id, type, since

	class Filter
		constructor: (@repo) ->
			if not @repo._eventEmitter? then throw new IllegalArgumentsError
			@anyTask = true
			@joinedGroups = {}
			for typeId, group of @repo.getGroups()
				@joinedGroups[typeId] = true
			@joinedTasks = {}
			@repo._eventEmitter.on 'afterRemoveGroupByTypeId', (event) =>
				delete @joinedGroups[event.args[0]]
			@repo._eventEmitter.on 'afterRemoveTaskById', (event) =>
				delete @joinedTasks[event.args[0]]

		joinAnyTask: -> @anyTask = true

		leaveAnyTask: -> @anyTask = false

		toggleAnyTask: -> @anyTask = not @anyTask

		anyTaskJoined: -> @anyTask

		joinGroup: (group) ->
			if not @repo.getGroupByTypeId(group.type.id)? or
			@joinedGroups[group.type.id]?
				throw new ConstraintError
			@joinedGroups[group.type.id] = true

		leaveGroup: (group) ->
			if not @repo.getGroupByTypeId(group.type.id)? or
			not @joinedGroups[group.type.id]?
				throw new ConstraintError
			delete @joinedGroups[group.type.id]

		groupJoined: (group) ->
			if not @repo.getGroupByTypeId(group.type.id)?
				throw new ConstraintError
			@joinedGroups[group.type.id]?

		toggleGroup: (group) ->
			if @groupJoined group
				@leaveGroup group
			else
				@joinGroup group

		joinTask: (task) ->
			if not @repo.getTaskById(task.id)? or
			@joinedTasks[task.id]?
				throw new ConstraintError
			@joinedTasks[task.id] = true

		leaveTask: (task) ->
			if not @repo.getTaskById(task.id)? or
			not @joinedTasks[task.id]?
				throw new ConstraintError
			delete @joinedTasks[task.id]

		taskJoined: (task) ->
			if not @repo.getTaskById(task.id)?
				throw new ConstraintError
			@joinedTasks[task.id]?

		toggleTask: (task) ->
			if @taskJoined task
				@leaveTask task
			else
				@joinTask task

		accepts: (task) ->
			if not @repo.getTaskById(task.id)?
				throw new ConstraintError
			@anyTask or
			@groupJoined(@repo.getGroupByTypeId(task.type.id)) or
			@taskJoined task

	externalizer =
		repo:
			export: (repo) ->
				result = {}
				for typeId, type of repo.getTypes()
					result[typeId] = {sampleInput: type.sampleInput,  tasks: {}}
					group = repo.getGroupByTypeId(typeId)
					if group?
						for taskId, task of group.tasks
							result[typeId].tasks[taskId] = {since: task.since}
				result

			import: (external, eventEmitter) ->
				repo = new Repo eventEmitter
				for typeIdSrc, typeSrc of external
					type = repo.addType Type.asType typeIdSrc
					type.sampleInput = typeSrc.sampleInput
					group = repo.addGroup Group.asGroup type
					for taskIdSrc, taskSrc of typeSrc.tasks
						group.addTask Task.asTask(taskIdSrc, type, taskSrc.since)
				repo
		type: # yeah, a bit redundant this time
			export: (type) -> {id: type.id, sampleInput: type.sampleInput}
			import: (external) -> Type.asType external.id, external.sampleInput
		group:
			export: (group) -> {typeId: group.type.id}
			import: (external) -> Group.asGroup Type.asType external.typeId
		task:
			export: (task) -> {id: task.id, typeId: task.type.id, since: task.since}
			import: (external) ->
				Task.asTask external.id, Type.asType(external.typeId), external.since

	replicated =
		repo: (socket, resolver, repoHolder = holder new Repo) ->
			proxy = eventProxy resolvingProxy repoHolder, resolver
			proxy._eventEmitter.on 'afterAddType', (event) ->
				socket.emit 'addType', externalizer.type.export event.value
			proxy._eventEmitter.on 'afterRemoveTypeById', (event) ->
				socket.emit 'removeType', event.value.id
			proxy._eventEmitter.on 'afterAddGroup', (event) ->
				socket.emit 'addGroup', externalizer.group.export event.value
			proxy._eventEmitter.on 'afterRemoveGroupById', (event) ->
				socket.emit 'removeGroup', event.value.id
			proxy._eventEmitter.on 'afterAddTask', (event) ->
				socket.emit 'addTask', externalizer.task.export event.value
			proxy._eventEmitter.on 'afterRemoveTaskById', (event) ->
				socket.emit 'addTask', event.value.id
			socket.on 'addType', (task) -> proxy.addTask externalizer.type.import type
			socket.on 'removeType', (id) -> proxy.removeTypeById id
			socket.on 'addGroup', (group) -> proxy.addGroup externalizer.group.import group
			socket.on 'removeGroup', (id) -> proxy.removeGroupByTypeId id
			socket.on 'addTask', (task) -> proxy.addTask externalizer.task.import task
			socket.on 'removeTask', (id) -> proxy.removeTaskById id
			socket.on 'pushingRepo', (repo) -> repoHolder._hold externalizer.repo.import repo
			socket.on 'pullingRepo', -> socket.emit 'pushingRepo', externalizer.repo.export repoHolder
			proxy._holder = repoHolder
			proxy

	exports.Repo = Repo
	exports.Group = Group
	exports.Type = Type
	exports.Task = Task
	exports.externalizer = externalizer
	exports.Filter = Filter
	exports.replicated = replicated
)(
	(if exports? then exports else @tasks = {}),
	(if @utils? then @utils else require './utils')
)
