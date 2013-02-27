((exports, EventEmitter, utils) ->
	ConstraintError = utils.ConstraintError

	class Repo
		constructor: ->
			@types = {}
			@groups = {}

		getTypes: -> @types

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
			if @getGroupByTypeId(group.type.id)? or
			not @getTypeById(group.type.id)? or
			group.getTaskCount() > 0
				throw new ConstraintError
			@groups[group.type.id] = group
			group.repo = @
			group.type = @getTypeById group.type.id
			group.on 'addTask', (addedTask) =>
				@emit 'addTask', addedTask
			group.on 'removeTask', (addedTask) =>
				@emit 'removeTask', addedTask
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

	utils.mixin Repo, EventEmitter

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

	class Filter
		constructor: (@repo) ->
			@anyTask = true
			@joinedGroups = {}
			for typeId, group of @repo.groups
				@joinedGroups[typeId] = true
			@joinedTasks = {}
			@repo.on 'removeGroup', (group) =>
				delete @joinedGroups[group.type.id]
			@repo.on 'removeTask', (task) =>
				delete @joinedTasks[task.id]

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

	wrap =
		repo: as:
			slave: (repo, externalizer, client) ->
				pullRepo = -> client.emit 'pullRepo'
				proxy = utils.wrap repo, utils.resolveWrapper pullRepo
				proxy.on 'addTask', (task) -> client.emit 'addTask', externalizer.task.export task
				client.on 'addType', (task) -> proxy.addTask externalizer.type.import type
				client.on 'removeType', (id) -> proxy.removeTypeById id
				client.on 'addGroup', (group) -> proxy.addGroup externalizer.group.import group
				client.on 'removeGroup', (id) -> proxy.removeGroupByTypeId id
				client.on 'addTask', (task) -> proxy.addTask externalizer.task.import task
				client.on 'removeTask', (id) -> proxy.removeTaskById id
				client.on 'pushRepo', (repo) -> proxy.push externalizer.repo.import repo
				pullRepo()
				proxy
			master: (repo, externalizer, socket) ->
				pushRepo = -> socket.emit 'pushRepo', externalizer.repo.export repo
				proxy = utils.wrap repo, utils.resolveWrapper pushRepo
				proxy.on 'addType', (type) -> socket.emit 'addType', externalizer.type.export type
				proxy.on 'removeType', (type) -> socket.emit 'removeType', type.id
				proxy.on 'addGroup', (group) -> socket.emit 'addGroup', externalizer.group.export group
				proxy.on 'removeGroup', (group) -> socket.emit 'removeGroup', group.type.id
				proxy.on 'addTask', (task) -> socket.emit 'addTask', externalizer.task.export task
				proxy.on 'removeTask', (task) -> socket.emit 'removeTask', task.id
				socket.on 'addTask', (task) -> proxy.addTask externalizer.task.import task
				socket.on 'pullRepo', pushRepo
				proxy

	externalizer =
		repo:
			export: (repo) ->
				result = {}
				for typeId, type of repo.getTypes()
					result[typeId] = {sampleInput: type.sampleInput,  tasks: {}}
					for taskId, task of repo.getGroupByTypeId(typeId).tasks
						result[typeId].tasks[taskId] = {since: task.since}
				result

			import: (external) ->
				repo = new Repo
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

	exports.Repo = Repo
	exports.Group = Group
	exports.Type = Type
	exports.Task = Task
	exports.externalizer = externalizer
	exports.Filter = Filter
)(
	(if exports? then exports else @tasks = {}),
	(if @EventEmitter? then @EventEmitter else require('events').EventEmitter),
	(if @utils? then @utils else require './utils')
)
