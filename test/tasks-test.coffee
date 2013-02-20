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


	describe 'Group', ->
		it 'should add, remove, retrieve and count tasks', ->
			myType = asType 'myType'
			group = asGroup myType
			myTask = group.addTask asTask('myTask', myType)
			group.getTaskById('myTask').should.equal myTask
			group.getTaskCount().should.equal 1

			(-> group.addTask asTask('myTask', myType)).should.throw tasks.ConstraintError

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

# TODO
#		it 'should not allow to add task with id that already exists in repo', ->

)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @tasks? then @tasks else require '../src/tasks')
)
