((should, tasks) ->
	asType = tasks.Type.asType
	asGroup = tasks.Group.asGroup
	asTask = tasks.Task.asTask

	describe 'Repo', ->
		it 'should add, remove, retrieve and count types', ->
			repo = new tasks.Repo
			repo.getTypeCount().should.equal 0

			myType = repo.addType asType 'myType', 'sampleInput'
			repo.getTypeById('myType').should.eql myType
			repo.getTypeCount().should.equal 1

			(-> repo.addType asType 'myType').should.throw tasks.ConstraintError

			removedType = repo.removeTypeById 'myType'
			removedType.should.eql myType
			should.not.exist repo.getTypeById 'myType'
			repo.getTypeCount().should.equal 0

			(-> repo.removeTypeById 'myType').should.throw tasks.ConstraintError

		it 'should emit addType event', ->
			repo = new tasks.Repo
			myType = asType 'myType', 'sampleInput'
			repo.on 'addType', (type) ->
				type.should.eql myType
				repo.getTypeById('myType').should.eql myType
				repo.getTypeCount().should.equal 1
			repo.addType myType

		it 'should emit removeType event', ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType', 'sampleInput'
			repo.on 'removeType', (type) ->
				type.should.eql myType
				should.not.exist repo.getTypeById 'myType'
				repo.getTypeCount().should.equal 0
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
			repo.getGroupByTypeId('myType').should.eql group
			repo.getGroupCount().should.equal 1
			group.repo.should.equal repo

			(-> repo.addGroup asGroup myType).should.throw tasks.ConstraintError

			removedGroup = repo.removeGroupByTypeId 'myType'
			removedGroup.should.eql group
			should.not.exist removedGroup.repo
			should.not.exist repo.getGroupByTypeId 'myType'
			repo.getGroupCount().should.equal 0

			(-> repo.removeGroupByTypeId 'myType').should.throw tasks.ConstraintError

		it 'should emit addGroup event', ->
			repo = new tasks.Repo
			group = asGroup repo.addType asType 'myType'
			repo.on 'addGroup', (addedGroup) ->
				addedGroup.should.eql group
				repo.getGroupByTypeId('myType').should.eql addedGroup
				repo.getGroupCount().should.equal 1
			repo.addGroup group

		it 'should emit removeGroup event', ->
			repo = new tasks.Repo
			group = repo.addGroup asGroup repo.addType asType 'myType'
			repo.on 'removeGroup', (removedGroup) ->
				removedGroup.should.eql group
				should.not.exist repo.getGroupByTypeId 'myType'
				repo.getGroupCount().should.equal 0
			repo.removeGroupByTypeId 'myType'

		it 'should not allow to remove not empty group', ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType'
			group = repo.addGroup asGroup myType
			group.addTask asTask 'myTask', myType
			(-> repo.removeGroupByTypeId 'myType')
				.should.throw tasks.ConstraintError

		it 'should not allow to add a group of type that has not been added to repo', ->
			repo = new tasks.Repo
			(-> repo.addGroup asGroup asType 'myType')
				.should.throw tasks.ConstraintError

	describe 'Group', ->
		it 'should add, remove, retrieve and count tasks', ->
			myType = asType 'myType'
			group = asGroup myType
			myTask = group.addTask asTask 'myTask', myType
			group.getTaskById('myTask').should.eql myTask
			group.getTaskCount().should.equal 1

			(-> group.addTask asTask 'myTask', myType).should.throw tasks.ConstraintError

			removedTask = group.removeTaskById 'myTask'
			removedTask.should.eql myTask
			should.not.exist group.getTaskById 'myTask'
			group.getTaskCount().should.equal 0

			(-> group.removeTaskById 'myTask').should.throw tasks.ConstraintError

		it 'should not allow to add task with improper type', ->
			group = asGroup asType 'myType'
			(-> group.addTask asTask('myTask'), asType('wrongType'))
				.should.throw tasks.ConstraintError

# TODO
#		it 'should not allow to add task with id that already exists in repo', ->

)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @tasks? then @tasks else require '../src/tasks')
)
