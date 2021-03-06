((should, deferred, tasks, EventEmitter, messaging, utils) ->
	asType = tasks.Type.asType
	asGroup = tasks.Group.asGroup
	asTask = tasks.Task.asTask
	eventProxy = utils.eventProxy
	ConstraintError = utils.ConstraintError
	IllegalArgumentsError = utils.IllegalArgumentsError

	describe 'tasks', ->
		describe 'Repo', ->
			it 'should return typeId->type map via getter', ->
				repo = new tasks.Repo
				myType = repo.addType asType 'myType'
				anotherType = repo.addType asType 'anotherType'
				types = repo.getTypes()
				types.myType.should.equal myType
				types.anotherType.should.equal anotherType
				utils.countKeys(types).should.equal 2

			it 'should return typeId->group map via getter', ->
				repo = new tasks.Repo
				myGroup = repo.addGroup asGroup repo.addType asType 'myType'
				anotherGroup = repo.addGroup asGroup repo.addType asType 'anotherType'
				groups = repo.getGroups()
				groups.myType.should.equal myGroup
				groups.anotherType.should.equal anotherGroup
				utils.countKeys(groups).should.equal 2

			it 'should add, remove, retrieve and count types', ->
				repo = new tasks.Repo
				repo.getTypeCount().should.equal 0

				myType = repo.addType asType 'myType', 'sampleInput'
				repo.getTypeById('myType').should.equal myType
				repo.getTypeCount().should.equal 1

				(-> repo.addType asType 'myType').should.throw ConstraintError

				removedType = repo.removeTypeById 'myType'
				removedType.should.equal myType
				should.not.exist repo.getTypeById 'myType'
				repo.getTypeCount().should.equal 0

				(-> repo.removeTypeById 'myType').should.throw ConstraintError

			it 'should not allow to remove the type when correspondent group exists', ->
				repo = new tasks.Repo
				myType = repo.addType asType 'myType'
				repo.addGroup asGroup myType
				(-> repo.removeTypeById 'myType').should.throw ConstraintError

			it 'should add, remove, retrieve and count groups', ->
				repo = new tasks.Repo
				myType = repo.addType asType 'myType'
				repo.getGroupCount().should.equal 0

				group = asGroup myType
				should.not.exist group.repo

				repo.addGroup group
				repo.getGroupByTypeId('myType').should.equal group
				repo.getGroupCount().should.equal 1
				group.repo.should.equal repo

				(-> repo.addGroup asGroup myType).should.throw ConstraintError

				removedGroup = repo.removeGroupByTypeId 'myType'
				removedGroup.should.equal group
				should.not.exist removedGroup.repo
				should.not.exist repo.getGroupByTypeId 'myType'
				repo.getGroupCount().should.equal 0

				(-> repo.removeGroupByTypeId 'myType').should.throw ConstraintError

			it 'should not allow to add not empty groups', ->
				# Otherwise we will have to replace referenced entities
				# for all the object graph.
				# See 'should replace Task#type with' and
				# 'should replace Group#type with' tests.
				# This constraint is acceptable and simplifies the Repo logic a lot.
				repo = new tasks.Repo
				myType = repo.addType asType 'myType'
				group = asGroup myType
				group.addTask asTask('myTask', myType)

				(-> repo.addGroup group).should.throw ConstraintError

			it 'should not allow to remove not empty group', ->
				repo = new tasks.Repo
				myType = repo.addType asType 'myType'
				group = repo.addGroup asGroup myType
				group.addTask asTask('myTask', myType)
				(-> repo.removeGroupByTypeId 'myType')
					.should.throw ConstraintError

			it 'should not allow to add a group of type that has not been added to repo', ->
				repo = new tasks.Repo
				(-> repo.addGroup asGroup asType 'myType')
					.should.throw ConstraintError

			it 'should replace Group#type with referential ("persisted") Type instance', ->
				repo = new tasks.Repo
				myType = repo.addType asType 'myType', 'sampleInput'
				myType2 = asType 'myType'
				group = asGroup myType2

				myType.id.should.equal myType2.id
				myType.should.not.equal group.type

				repo.addGroup group
				myType.should.equal group.type
				group.type.sampleInput.should.equal 'sampleInput'

			it 'should search tasks by id through all the repo', ->
				repo = new tasks.Repo
				myType = repo.addType asType 'myType'
				anotherType = repo.addType asType 'anotherType'
				myGroup = repo.addGroup asGroup myType
				anotherGroup = repo.addGroup asGroup anotherType
				myTask = myGroup.addTask asTask('myTask', myType)
				anotherTask = anotherGroup.addTask asTask('anotherTask', anotherType)

				repo.getTaskById('myTask').should.equal myTask
				repo.getTaskById('anotherTask').should.equal anotherTask

			it 'should add tasks to proper group and remove them', ->
				repo = new tasks.Repo
				myType = repo.addType asType 'myType'
				anotherType = repo.addType asType 'anotherType'
				myGroup = repo.addGroup asGroup myType
				anotherGroup = repo.addGroup asGroup anotherType
				myTask = repo.addTask asTask('myTask', myType)
				anotherTask = repo.addTask asTask('anotherTask', anotherType)

				myGroup.getTaskById('myTask').should.equal myTask
				myGroup.getTaskCount().should.equal 1
				anotherGroup.getTaskById('anotherTask').should.equal anotherTask
				anotherGroup.getTaskCount().should.equal 1

				repo.removeTaskById 'myTask'
				should.not.exist myGroup.getTaskById 'myTask'
				myGroup.getTaskCount().should.equal 0
				anotherGroup.getTaskCount().should.equal 1
				repo.removeTaskById 'anotherTask'
				should.not.exist anotherGroup.getTaskById 'anotherTask'
				anotherGroup.getTaskCount().should.equal 0

			it 'should count tasks through all the repo', ->
				repo = new tasks.Repo
				myType = repo.addType asType 'myType'
				anotherType = repo.addType asType 'anotherType'
				repo.addGroup asGroup myType
				repo.addGroup asGroup anotherType

				repo.getTaskCount().should.equal 0
				repo.addTask asTask('myTask', myType)
				repo.addTask asTask('oneMoreTask', myType)
				repo.addTask asTask('anotherTask', anotherType)
				repo.getTaskCount().should.equal 3

		describe 'Group', ->
			it 'should add, remove, retrieve and count tasks', ->
				myType = asType 'myType'
				group = asGroup myType
				myTask = group.addTask asTask('myTask', myType)
				group.getTaskById('myTask').should.equal myTask
				group.getTaskCount().should.equal 1

				(-> group.addTask asTask('myTask', myType))
					.should.throw ConstraintError

				removedTask = group.removeTaskById 'myTask'
				removedTask.should.equal myTask
				should.not.exist group.getTaskById 'myTask'
				group.getTaskCount().should.equal 0

				(-> group.removeTaskById 'myTask').should.throw ConstraintError

			it 'should not allow to add task with improper type', ->
				group = asGroup asType 'myType'
				(-> group.addTask asTask('myTask', asType 'wrongType'))
					.should.throw ConstraintError

			it 'should replace Task#type with referential ("persisted") Type instance', ->
				myType = asType 'myType'
				myType2 = asType 'myType'
				group = asGroup myType
				myTask = asTask 'myTask', myType2

				myType.id.should.equal myType2.id
				myType.should.not.equal myTask.type

				group.addTask myTask
				myType.should.equal myTask.type

			it 'should not allow to add task with id that already exists in repo', ->
				repo = new tasks.Repo
				myType = repo.addType asType 'myType'
				anotherType = repo.addType asType 'anotherType'
				myGroup = repo.addGroup asGroup myType
				anotherGroup = repo.addGroup asGroup anotherType
				myGroup.addTask asTask('myTask', myType)

				(-> anotherGroup.addTask asTask('myTask', anotherType))
					.should.throw ConstraintError

		describe 'externalizer', ->
			describe 'repo', ->
				it 'should export', ->
					since = new Date
					repo = new tasks.Repo
					myType = repo.addType asType('myType', 'sampleInput')
					anotherType = repo.addType asType 'anotherType'
					repo.addGroup asGroup myType
					repo.addGroup asGroup anotherType
					repo.addTask asTask('myTask', myType, since)
					repo.addTask asTask('oneMoreTask', myType, since)
					repo.addTask asTask('anotherTask', anotherType, since)

					tasks.externalizer.repo.export(repo).should.eql
						myType:
							sampleInput: 'sampleInput'
							tasks:
								myTask: {since: since}
								oneMoreTask: {since: since}
						anotherType:
							sampleInput: undefined
							tasks:
								anotherTask: {since: since}

				it 'should export repo that does not have any groups', ->
					since = new Date
					repo = new tasks.Repo
					myType = repo.addType asType('myType', 'sampleInput')
					anotherType = repo.addType asType 'anotherType'

					tasks.externalizer.repo.export(repo).should.eql
						myType:
							sampleInput: 'sampleInput'
							tasks: {}
						anotherType:
							sampleInput: undefined
							tasks: {}

				it 'should import', ->
					since = new Date
					repo = tasks.externalizer.repo.import
						myType:
							sampleInput: 'sampleInput'
							tasks:
								myTask: {since: since}
								oneMoreTask: {since: since}
						anotherType:
							sampleInput: undefined
							tasks:
								anotherTask: {since: since}

					repo.should.be.an.instanceof tasks.Repo
					repo.getTypeCount().should.equal 2
					should.exist repo.getTypeById 'myType'
					should.exist repo.getTypeById 'anotherType'
					repo.getTaskCount().should.equal 3
					repo.getGroupCount().should.equal 2

					myGroup = repo.getGroupByTypeId 'myType'
					should.exist myGroup
					myGroup.getTaskCount().should.equal 2
					myTask = myGroup.getTaskById 'myTask'
					should.exist myTask
					myTask.since.should.equal since
					oneMoreTask = myGroup.getTaskById 'oneMoreTask'
					should.exist oneMoreTask
					oneMoreTask.since.should.equal since

					anotherGroup = repo.getGroupByTypeId 'anotherType'
					should.exist anotherGroup
					anotherGroup.getTaskCount().should.equal 1
					anotherTask = anotherGroup.getTaskById 'anotherTask'
					should.exist anotherTask
					anotherTask.since.should.equal since

			describe 'type', ->
				it 'should export', ->
					external = tasks.externalizer.type.export asType 'myType', 'sampleInput'
					external.should.eql {id: 'myType', sampleInput: 'sampleInput'}

				it 'should import', ->
					type = tasks.externalizer.type.import {id: 'myType', sampleInput: 'sampleInput'}
					type.should.be.an.instanceof tasks.Type
					type.id.should.equal 'myType'
					type.sampleInput.should.equal 'sampleInput'

			describe 'group', ->
				it 'should export', ->
					external = tasks.externalizer.group.export asGroup asType 'myType'
					external.should.eql {typeId: 'myType'}

				it 'should import', ->
					group = tasks.externalizer.group.import {typeId: 'myType'}
					group.should.be.an.instanceof tasks.Group
					group.type.should.be.an.instanceof tasks.Type
					group.type.id.should.equal 'myType'

			describe 'task', ->
				it 'should export', ->
					since = new Date
					repo = new tasks.Repo
					myType = repo.addType asType 'myType', 'sampleInput'
					repo.addGroup asGroup myType
					myTask = repo.addTask asTask 'myTask', myType, since
					external = tasks.externalizer.task.export myTask
					external.should.eql {id: 'myTask', typeId: 'myType', since: since}

				it 'should import', ->
					since = new Date
					task = tasks.externalizer.task.import {id: 'myTask', typeId: 'myType', since: since}
					task.should.be.an.instanceof tasks.Task
					task.type.should.be.an.instanceof tasks.Type
					task.id.should.equal 'myTask'
					task.type.id.should.equal 'myType'
					task.since.should.equal since

		describe 'Filter', ->
			it 'should throw IllegalArgumentError when could not obtain EventEmitter instance', ->
				(-> new tasks.Filter new tasks.Repo).should.throw IllegalArgumentsError

			it 'should let join, leave, toggle any task', ->
				filter = new tasks.Filter eventProxy new tasks.Repo
				filter.anyTaskJoined().should.be.true
				filter.leaveAnyTask()
				filter.anyTaskJoined().should.be.false
				filter.joinAnyTask()
				filter.anyTaskJoined().should.be.true
				filter.toggleAnyTask()
				filter.anyTaskJoined().should.be.false
				filter.toggleAnyTask()
				filter.anyTaskJoined().should.be.true

			it 'should let join, leave, toggle group', ->
				repo = eventProxy new tasks.Repo
				myGroup = repo.addGroup asGroup repo.addType asType 'myType'
				anotherGroup = repo.addGroup asGroup repo.addType asType 'anotherType'
				filter = new tasks.Filter repo

				filter.groupJoined(myGroup).should.be.true
				filter.groupJoined(anotherGroup).should.be.true
				filter.leaveGroup myGroup
				filter.groupJoined(myGroup).should.be.false
				filter.groupJoined(anotherGroup).should.be.true
				filter.joinGroup myGroup
				filter.groupJoined(myGroup).should.be.true
				filter.toggleGroup myGroup
				filter.groupJoined(myGroup).should.be.false
				filter.toggleGroup myGroup
				filter.groupJoined(myGroup).should.be.true

			it 'should let join, leave, toggle task', ->
				repo = eventProxy new tasks.Repo
				filter = new tasks.Filter repo
				myGroup = repo.addGroup asGroup repo.addType asType 'myType'
				anotherGroup = repo.addGroup asGroup repo.addType asType 'anotherType'
				myTask = repo.addTask asTask('myTask', myGroup.type)
				oneMoreTask = repo.addTask asTask('oneMoreTask', myGroup.type)
				anotherTask = repo.addTask asTask('anotherTask', anotherGroup.type)

				filter.taskJoined(myTask).should.be.false
				filter.taskJoined(oneMoreTask).should.be.false
				filter.taskJoined(anotherTask).should.be.false
				filter.joinTask myTask
				filter.taskJoined(myTask).should.be.true
				filter.taskJoined(oneMoreTask).should.be.false
				filter.taskJoined(anotherTask).should.be.false
				filter.leaveTask myTask
				filter.taskJoined(myTask).should.be.false
				filter.toggleTask myTask
				filter.taskJoined(myTask).should.be.true
				filter.toggleTask myTask
				filter.taskJoined(myTask).should.be.false

			it 'should accept proper tasks', ->
				repo = eventProxy new tasks.Repo
				myGroup = repo.addGroup asGroup repo.addType asType 'myType'
				anotherGroup = repo.addGroup asGroup repo.addType asType 'anotherType'
				myTask = repo.addTask asTask('myTask', myGroup.type)
				oneMoreTask = repo.addTask asTask('oneMoreTask', myGroup.type)
				anotherTask = repo.addTask asTask('anotherTask', anotherGroup.type)
				filter = new tasks.Filter repo

				filter.accepts(myTask).should.be.true
				filter.accepts(oneMoreTask).should.be.true
				filter.accepts(anotherTask).should.be.true

				filter.leaveAnyTask()
				filter.accepts(myTask).should.be.true
				filter.accepts(oneMoreTask).should.be.true
				filter.accepts(anotherTask).should.be.true

				filter.leaveGroup myGroup
				filter.accepts(myTask).should.be.false
				filter.accepts(oneMoreTask).should.be.false
				filter.accepts(anotherTask).should.be.true

				filter.joinTask myTask
				filter.accepts(myTask).should.be.true
				filter.accepts(oneMoreTask).should.be.false
				filter.accepts(anotherTask).should.be.true

			it 'should not track newly added groups', ->
				repo = eventProxy new tasks.Repo
				myGroup = repo.addGroup asGroup repo.addType asType 'myType'
				filter = new tasks.Filter repo
				anotherGroup = repo.addGroup asGroup repo.addType asType 'anotherType'

				filter.groupJoined(myGroup).should.be.true
				filter.groupJoined(anotherGroup).should.be.false

			it 'should track when group is removed', ->
				repo = eventProxy new tasks.Repo
				myGroup = repo.addGroup asGroup repo.addType asType 'myType'
				anotherGroup = repo.addGroup asGroup repo.addType asType 'anotherType'
				filter = new tasks.Filter repo

				filter.groupJoined(myGroup).should.be.true
				filter.groupJoined(anotherGroup).should.be.true

				repo.removeGroupByTypeId 'myType'
				(-> filter.groupJoined myGroup).should.throw ConstraintError
				should.not.exist filter.joinedGroups['myType']
				filter.groupJoined(anotherGroup).should.be.true

			it 'should track when task is removed', ->
				repo = eventProxy new tasks.Repo
				myGroup = repo.addGroup asGroup repo.addType asType 'myType'
				anotherGroup = repo.addGroup asGroup repo.addType asType 'anotherType'
				myTask = repo.addTask asTask('myTask', myGroup.type)
				oneMoreTask = repo.addTask asTask('oneMoreTask', myGroup.type)
				anotherTask = repo.addTask asTask('anotherTask', anotherGroup.type)
				filter = new tasks.Filter repo

				repo.removeTaskById 'myTask'
				(-> filter.taskJoined myTask).should.throw ConstraintError
				should.not.exist filter.joinedTasks['myTask']
				filter.taskJoined(oneMoreTask).should.be.false
				filter.taskJoined(anotherTask).should.be.false

			it 'should not let to deal with the groups whose ids that are not in repo', ->
				repo = eventProxy new tasks.Repo
				myType = repo.addType asType 'myType'
				filter = new tasks.Filter repo
				myGroup = asGroup myType

				(-> filter.joinGroup myGroup).should.throw ConstraintError

				repo.addGroup myGroup
				filter.joinGroup myGroup
				delete repo.getGroups().myType # Never do this IRL! Only for test purposes.
				(-> filter.leaveGroup myGroup).should.throw ConstraintError
				(-> filter.groupJoined myGroup).should.throw ConstraintError
				(-> filter.toggleGroup myGroup).should.throw ConstraintError

			it 'should not let to deal with the tasks whose ids that are not in repo', ->
				repo = eventProxy new tasks.Repo
				myGroup = repo.addGroup asGroup repo.addType asType 'myType'
				filter = new tasks.Filter repo
				myTask = asTask 'myTask', myGroup.type

				(-> filter.joinTask myTask).should.throw ConstraintError

				repo.addTask myTask
				filter.joinTask myTask
				delete repo.getGroups().myType.tasks.myTask # Never do this IRL! Only for test purposes.
				(-> filter.leaveTask myTask).should.throw ConstraintError
				(-> filter.taskJoined myTask).should.throw ConstraintError
				(-> filter.toggleTask myTask).should.throw ConstraintError

			it 'should not let join the group when already joined and leave when not', ->
				repo = eventProxy new tasks.Repo
				myGroup = repo.addGroup asGroup repo.addType asType 'myType'
				filter = new tasks.Filter repo

				(-> filter.joinGroup myGroup).should.throw ConstraintError

				filter.leaveGroup myGroup
				(-> filter.leaveGroup myGroup).should.throw ConstraintError

			it 'should not let join the task when already joined and leave when not', ->
				repo = eventProxy new tasks.Repo
				myGroup = repo.addGroup asGroup repo.addType asType 'myType'
				myTask = repo.addTask asTask 'myTask', myGroup.type
				filter = new tasks.Filter repo

				filter.joinTask myTask
				(-> filter.joinGroup myGroup).should.throw ConstraintError

				filter.leaveTask myTask
				(-> filter.leaveTask myTask).should.throw ConstraintError

		describe 'replicated', ->
			describe 'repo', ->
				it 'should be done', (done) ->
					server = new messaging.InProcServer
					innerRepo = new tasks.Repo
					innerRepo.addType asType 'myType', 'sampleInput'
					masterRepo = null
					clientSocketA = (new messaging.InProcClient).connect server
					slaveRepoA = tasks.replicated.repo clientSocketA, -> clientSocketA.emit 'pullingRepo'

					deferred(server.waitForConnection(), clientSocketA.waitFor 'connect')
					.then ([s]) ->
						# TODO broadcasting!!!
						masterRepo = tasks.replicated.repo(
							s,
							(-> s.emit 'pushingRepo', tasks.externalizer.repo.export masterRepo),
							innerRepo
						)
						clientSocketA.emit 'pullingRepo'
						clientSocketA.waitFor 'pushingRepo'
					.then ->
						slaveRepoA.getTypes().myType.id.should.equal 'myType'
						slaveRepoA.getTypes().myType.sampleInput.should.equal 'sampleInput'
						utils.countKeys(slaveRepoA.getTypes()).should.equal 1
						done()

)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @deferred? then @deferred else require 'deferred'),
	(if @tasks? then @tasks else require '../src/tasks'),
	(if @EventEmitter? then @EventEmitter else require('events').EventEmitter),
	(if @messaging? then @messaging else require '../src/messaging'),
	(if @utils? then @utils else require '../src/utils')
)
