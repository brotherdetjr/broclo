((should, utils) ->

	ConstraintError = utils.ConstraintError
	NotImplementedError = utils.NotImplementedError

	class A
		constructor: (@a) ->

		setAndGetDoubledA: (a) ->
			@a = a
			a * 2

		getA: -> @a

	class B extends A
		constructor: (a, @b) ->
			super a

		setBAndGetAPlusB: (b) ->
			if not @a?
				throw new ConstraintError
			@b = b
			@a + @b

		getB: () -> @b

		throwingMethod: -> throw new NotImplementedError

	describe 'utils', ->
		describe 'resolvingProxy', (done) ->
			it 'should be transparent when ConstraintError is not thrown', ->
				proxy = utils.resolvingProxy new B
				proxy.setAndGetDoubledA(1).should.equal 2
				proxy.setBAndGetAPlusB(2).should.equal 3
				proxy.getB().should.equal 2

			it 'should call resolver function when ConstraintError is thrown', (done) ->
				proxy = utils.resolvingProxy new B, -> done()
				should.not.exist proxy.setBAndGetAPlusB 2
				should.not.exist proxy.getB()

			it 'should call rethrow other errors than ConstraintError', ->
				proxy = utils.resolvingProxy new B
				(-> proxy.throwingMethod()).should.throw NotImplementedError

		describe 'holder', (done) ->
			it 'should delegate calls to wrapped object', ->
				holder = utils.holder new A
				doubledA = holder.setAndGetDoubledA 33
				holder.getA().should.equal 33
				doubledA.should.equal 66

			it 'should take new content and delegate all the calls to it', ->
				holder = utils.holder new A 1
				holder.getA().should.equal 1
				holder.hold new A 2
				holder.getA().should.equal 2
)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @utils? then @utils else require '../src/utils')
)
