((should, tasks) ->
	asType = tasks.Type.asType

	describe 'Repo', ->
		it 'should add, remove, retrieve and count types', ->
			repo = new tasks.Repo
			repo.getTypeCount().should.equal 0

			myType = repo.addType asType 'myType', 'sampleInput'
			repo.getTypeById('myType').should.equal myType
			repo.getTypeCount().should.equal 1

			(-> repo.addType asType 'myType').should.throw

			removedType = repo.removeTypeById 'myType'
			removedType.should.equal myType
			should.not.exist repo.getTypeById 'myType'
			repo.getTypeCount().should.equal 0

			(-> repo.removeTypeById 'myType').should.throw

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

)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @tasks? then @tasks else require '../src/tasks')
)
