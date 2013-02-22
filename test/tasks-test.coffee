((should, tasks) ->
	asType = tasks.Type.asType
	asGroup = tasks.Group.asGroup
	asTask = tasks.Task.asTask

	describe 'Repo', ->
		it 'should add, remove, retrieve and count types', ->
			repo = new tasks.Repo
			repo.getTypeCount().should.equal 0

			myType = repo.addType asType 'myType', 'sampleInput'
			repo.getTypeById('myType').should.equal myType
			repo.getTypeCount().should.equal 1

			(-> repo.addType asType 'myType').should.throw tasks.ConstraintError

			removedType = repo.removeTypeById 'myType'
			removedType.should.equal myType
			should.not.exist repo.getTypeById 'myType'
			repo.getTypeCount().should.equal 0

			(-> repo.removeTypeById 'myType').should.throw tasks.ConstraintError

		it 'should emit addType event', (done) ->
			repo = new tasks.Repo
			myType = asType 'myType', 'sampleInput'
			repo.on 'addType', (type) ->
				type.should.equal myType
				repo.getTypeById('myType').should.equal myType
				repo.getTypeCount().should.equal 1
				done()
			repo.addType myType

		it 'should emit removeType event', (done) ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType', 'sampleInput'
			repo.on 'removeType', (type) ->
				type.should.equal myType
				should.not.exist repo.getTypeById 'myType'
				repo.getTypeCount().should.equal 0
				done()
			repo.removeTypeById 'myType'

		it 'should not allow to remove the type when correspondent group exists', ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType'
			repo.addGroup asGroup myType
			(-> repo.removeTypeById 'myType').should.throw tasks.ConstraintError

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

			(-> repo.addGroup asGroup myType).should.throw tasks.ConstraintError

			removedGroup = repo.removeGroupByTypeId 'myType'
			removedGroup.should.equal group
			should.not.exist removedGroup.repo
			should.not.exist repo.getGroupByTypeId 'myType'
			repo.getGroupCount().should.equal 0

			(-> repo.removeGroupByTypeId 'myType').should.throw tasks.ConstraintError

		it 'should emit addGroup event', (done) ->
			repo = new tasks.Repo
			group = asGroup repo.addType asType 'myType'
			repo.on 'addGroup', (addedGroup) ->
				addedGroup.should.equal group
				repo.getGroupByTypeId('myType').should.equal addedGroup
				repo.getGroupCount().should.equal 1
				done()
			repo.addGroup group

		it 'should emit removeGroup event', (done) ->
			repo = new tasks.Repo
			group = repo.addGroup asGroup repo.addType asType 'myType'
			repo.on 'removeGroup', (removedGroup) ->
				removedGroup.should.equal group
				should.not.exist repo.getGroupByTypeId 'myType'
				repo.getGroupCount().should.equal 0
				done()
			repo.removeGroupByTypeId 'myType'

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

			(-> repo.addGroup group).should.throw tasks.ConstraintError

		it 'should not allow to remove not empty group', ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType'
			group = repo.addGroup asGroup myType
			group.addTask asTask('myTask', myType)
			(-> repo.removeGroupByTypeId 'myType')
				.should.throw tasks.ConstraintError

		it 'should not allow to add a group of type that has not been added to repo', ->
			repo = new tasks.Repo
			(-> repo.addGroup asGroup asType 'myType')
				.should.throw tasks.ConstraintError

		it 'should replace Group#type with referential ("persisted") Type instance', ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType'
			myType2 = asType 'myType'
			group = asGroup myType2

			myType.id.should.equal myType2.id
			myType.should.not.equal group.type

			repo.addGroup group
			myType.should.equal group.type

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

		it 'should delegate addTask event', (done) ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType'
			myTask = asTask 'myTask', myType
			repo.on 'addTask', (addedTask) ->
				addedTask.should.equal myTask
				repo.getTaskById('myTask').should.equal addedTask
				repo.getTaskCount().should.equal 1
				done()
			group = repo.addGroup asGroup myType
			group.addTask myTask

		it 'should delegate removeTask event', (done) ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType'
			group = repo.addGroup asGroup myType
			myTask = repo.addTask asTask('myTask', myType)
			repo.on 'removeTask', (removedTask) ->
				removedTask.should.equal myTask
				should.not.exist repo.getTaskById('myTask')
				repo.getTaskCount().should.equal 0
				done()
			group.removeTaskById 'myTask'

	describe 'Group', ->
		it 'should add, remove, retrieve and count tasks', ->
			myType = asType 'myType'
			group = asGroup myType
			myTask = group.addTask asTask('myTask', myType)
			group.getTaskById('myTask').should.equal myTask
			group.getTaskCount().should.equal 1

			(-> group.addTask asTask('myTask', myType))
				.should.throw tasks.ConstraintError

			removedTask = group.removeTaskById 'myTask'
			removedTask.should.equal myTask
			should.not.exist group.getTaskById 'myTask'
			group.getTaskCount().should.equal 0

			(-> group.removeTaskById 'myTask').should.throw tasks.ConstraintError

		it 'should emit addTask event', (done) ->
			group = asGroup asType 'myType'
			myTask = asTask 'myTask', group.type
			group.on 'addTask', (addedTask) ->
				addedTask.should.equal myTask
				group.getTaskById('myTask').should.equal addedTask
				group.getTaskCount().should.equal 1
				done()
			group.addTask myTask

		it 'should emit removeTask event', (done) ->
			group = asGroup asType 'myType'
			myTask = group.addTask asTask('myTask', group.type)
			group.on 'removeTask', (removedTask) ->
				removedTask.should.equal myTask
				should.not.exist group.getTaskById 'myTask'
				group.getTaskCount().should.equal 0
				done()
			group.removeTaskById 'myTask'

		it 'should not allow to add task with improper type', ->
			group = asGroup asType 'myType'
			(-> group.addTask asTask('myTask', asType 'wrongType'))
				.should.throw tasks.ConstraintError

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
				.should.throw tasks.ConstraintError

	describe 'Externalizer', ->
		it 'should export repo', ->
			since = new Date
			repo = new tasks.Repo
			myType = repo.addType asType('myType', 'sampleInput')
			anotherType = repo.addType asType 'anotherType'
			repo.addGroup asGroup myType
			repo.addGroup asGroup anotherType
			repo.addTask asTask('myTask', myType, since)
			repo.addTask asTask('oneMoreTask', myType, since)
			repo.addTask asTask('anotherTask', anotherType, since)

			tasks.Externalizer.repo.export(repo).should.eql
				myType:
					sampleInput: 'sampleInput'
					tasks:
						myTask: {since: since}
						oneMoreTask: {since: since}
				anotherType:
					sampleInput: undefined
					tasks:
						anotherTask: {since: since}

		it 'should import repo', ->
			since = new Date
			repo = tasks.Externalizer.repo.import
				myType:
					sampleInput: 'sampleInput'
					tasks:
						myTask: {since: since}
						oneMoreTask: {since: since}
				anotherType:
					sampleInput: undefined
					tasks:
						anotherTask: {since: since}

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

	describe 'Filter', ->
		it 'should let join, leave, toggle any task', ->
			filter = new tasks.Filter new tasks.Repo
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
			repo = new tasks.Repo
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
			repo = new tasks.Repo
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
			repo = new tasks.Repo
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

)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @tasks? then @tasks else require '../src/tasks')
)
