((should, utils) ->

	ConstraintError = utils.ConstraintError

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

	describe 'utils.wrap', (done) ->
		it 'should be transparent when ConstraintError is not thrown', ->
			b = new B
			proxy = utils.wrap {src: b}
			proxy.setAndGetDoubledA(1).should.equal 2
			proxy.setBAndGetAPlusB(2).should.equal 3

		it 'should call resolveConflict() when ConstraintError is thrown', (done) ->
			b = new B
			proxy = utils.wrap
				src: b
				resolveConflict: (event) ->
					done()
			proxy.setBAndGetAPlusB 2
)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @utils? then @utils else require '../src/utils')
)
