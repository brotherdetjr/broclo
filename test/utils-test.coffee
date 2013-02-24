((should, utils) ->

	ConstraintError = utils.ConstraintError
	NotImplementedError = utils.NotImplementedError

	class A
		constructor: (@a) ->

		setAndGetDoubledA: (a) ->
			@a = a
			a * 2

	class B extends A
		constructor: (a, @b) ->
			super a

		setBAndGetAPlusB: (b) ->
			if not @a?
				throw new ConstraintError
			@b = b
			@a + @b

		throwingMethod: -> throw new NotImplementedError

	describe 'utils.resolveWrapper', (done) ->
		it 'should be transparent when ConstraintError is not thrown', ->
			proxy = utils.wrap new B, utils.resolveWrapper
			proxy.setAndGetDoubledA(1).should.equal 2
			proxy.setBAndGetAPlusB(2).should.equal 3

		it 'should call resolveConflict() when ConstraintError is thrown', (done) ->
			proxy = utils.wrap new B, utils.resolveWrapper, (event) -> done()
			proxy.setBAndGetAPlusB 2

		it 'should call rethrow other errors than ConstraintError', ->
			proxy = utils.wrap new B, utils.resolveWrapper
			(-> proxy.throwingMethod()).should.throw NotImplementedError
)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @utils? then @utils else require '../src/utils')
)
