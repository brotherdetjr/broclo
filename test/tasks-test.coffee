((should, tasks) ->
	asType = tasks.Type.asType
	asGroup = tasks.Group.asGroup

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

		it 'should emit addType event', ->
			repo = new tasks.Repo
			myType = asType 'myType', 'sampleInput'
			repo.on 'addType', (type) ->
				type.should.equal myType
				repo.getTypeById('myType').should.equal myType
				repo.getTypeCount().should.equal 1
			repo.addType myType

		it 'should emit removeType event', ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType', 'sampleInput'
			repo.on 'removeType', (type) ->
				type.should.equal myType
				should.not.exist repo.getTypeById 'myType'
				repo.getTypeCount().should.equal 0
			repo.removeTypeById 'myType'

		it 'should not allow to remove the type when correspondent group exists', ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType'
			repo.addGroup asGroup myType
			(-> repo.removeTypeById 'myType').should.throw tasks.ConstraintError

		it 'should add, remove, retrieve and count types', ->
			repo = new tasks.Repo
			myType = repo.addType asType 'myType'
			repo.getGroupCount().should.equal 0

			group = repo.addGroup asGroup myType
			repo.getGroupByTypeId('myType').should.equal group
			repo.getGroupCount().should.equal 1

			(-> repo.addGroup asGroup myType).should.throw tasks.ConstraintError

			removedGroup = repo.removeGroupByTypeId 'myType'
			removedGroup.should.equal group
			should.not.exist repo.getGroupByTypeId 'myType'
			repo.getGroupCount().should.equal 0

			(-> repo.removeGroupByTypeId 'myType').should.throw tasks.ConstraintError

		it 'should emit addGroup event', ->
			repo = new tasks.Repo
			group = asGroup repo.addType asType 'myType'
			repo.on 'addGroup', (addedGroup) ->
				addedGroup.should.equal group
				repo.getGroupByTypeId('myType').should.equal addedGroup
				repo.getGroupCount().should.equal 1
			repo.addGroup group

		it 'should emit removeGroup event', ->
			repo = new tasks.Repo
			group = repo.addGroup asGroup repo.addType asType 'myType'
			repo.on 'removeGroup', (removedGroup) ->
				removedGroup.should.equal group
				should.not.exist repo.getGroupByTypeId 'myType'
				repo.getGroupCount().should.equal 0
			repo.removeGroupByTypeId 'myType'

# TODO
#		it 'should not allow to remove not empty group', ->

		it 'should not allow to add a group of type that has not been added to repo', ->
			repo = new tasks.Repo
			(-> repo.addGroup asGroup asType 'myType')
				.should.throw tasks.ConstraintError
)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @tasks? then @tasks else require '../src/tasks')
)
