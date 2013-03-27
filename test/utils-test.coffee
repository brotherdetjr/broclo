((should, sinon, EventEmitter, utils) ->

	ConstraintError = utils.ConstraintError
	NotImplementedError = utils.NotImplementedError
	eventually = utils.eventually

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

		sum: (a, b) -> @sideEffect = a + b

		throwingMethod: -> throw new NotImplementedError

	describe 'utils', ->
		describe 'resolvingProxy', ->
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

		describe 'holder', ->
			it 'should delegate calls to wrapped object', ->
				holder = utils.holder new A
				doubledA = holder.setAndGetDoubledA 33
				holder.getA().should.equal 33
				doubledA.should.equal 66

			it 'should take new content and delegate all the calls to it', ->
				holder = utils.holder new A 1
				holder.getA().should.equal 1
				holder._hold new A 2
				holder.getA().should.equal 2

			it 'should return content being held', ->
				content = new A 1
				utils.holder(content)._getContent().should.equal content

		describe 'eventProxy', ->
			it 'should return the value returned by proxied method', ->
				proxy = utils.eventProxy new B
				proxy.sum(3, 4).should.equal 7

			it 'should emit "before" and "after" events', do ->
				emitter = new EventEmitter
				obj = new B

				beforeSpy = sinon.spy (event) ->
					event.obj.should.equal obj
					event.args[0].should.equal 2
					event.args[1].should.equal 3
					event.args.length.should.equal 2
					should.not.exist obj.sideEffect
				emitter.on 'beforeSum', beforeSpy

				afterSpy = sinon.spy (event) ->
					event.obj.should.equal obj
					event.args[0].should.equal 2
					event.args[1].should.equal 3
					event.args.length.should.equal 2
					event.value.should.equal 5
					obj.sideEffect.should.equal 5
				emitter.on 'afterSum', afterSpy

				throwedSpy = sinon.spy()
				emitter.on 'throwedSum', throwedSpy

				proxy = utils.eventProxy obj, emitter
				proxy.sum 2, 3

				eventually ->
					beforeSpy.calledOnce.should.be.true
					afterSpy.calledOnce.should.be.true
					afterSpy.calledAfter(beforeSpy).should.be.true
					throwedSpy.callCount.should.equal 0

			it 'should emit "before" and "throwed" events when method has thrown an error', do ->
				obj = new B
				proxy = utils.eventProxy obj

				beforeSpy = sinon.spy (event) ->
					event.obj.should.equal obj
					event.args[0].should.equal 2
					event.args[1].should.equal 3
					event.args.length.should.equal 2
				proxy._eventEmitter.on 'beforeThrowingMethod', beforeSpy

				afterSpy = sinon.spy()
				proxy._eventEmitter.on 'afterThrowingMethod', afterSpy

				throwedSpy = sinon.spy (event) ->
					event.obj.should.equal obj
					event.args[0].should.equal 2
					event.args[1].should.equal 3
					event.args.length.should.equal 2
					event.error.should.be.instanceof NotImplementedError
				proxy._eventEmitter.on 'throwedThrowingMethod', throwedSpy

				(-> proxy.throwingMethod 2, 3).should.throw NotImplementedError

				eventually ->
					beforeSpy.calledOnce.should.be.true
					afterSpy.callCount.should.equal 0
					throwedSpy.calledOnce.should.be.true
					throwedSpy.calledAfter(beforeSpy).should.be.true

			it 'should not emit any events when calling wrapped methods directly', do ->
				emitter = new EventEmitter
				obj = new B 1, 2
				proxy = utils.eventProxy obj, emitter
				spy = sinon.spy()
				emitter.on 'beforeGetB', spy
				emitter.on 'afterGetB', spy
				obj.getB

				eventually ->
					spy.callCount.should.equal 0

		describe 'capitalize', ->
			it 'should return the word with uppercased first letter', ->
				utils.capitalize('hello').should.equal 'Hello'
				utils.capitalize('a').should.equal 'A'

			it 'should leave the word unchanged if the symbol cannot be capitalized', ->
				utils.capitalize('123').should.equal '123'
				utils.capitalize('AAA').should.equal 'AAA'
				utils.capitalize(' leading space').should.equal ' leading space'

			it 'should leave empty string unchanged', ->
				utils.capitalize('').should.equal ''

)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @sinon? then @sinon else require('sinon')),
	(if @EventEmitter? then @EventEmitter else require('events').EventEmitter),
	(if @utils? then @utils else require '../src/utils')
)
