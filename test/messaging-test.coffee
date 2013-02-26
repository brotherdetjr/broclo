((should, sinon, utils, messaging) ->

	eventually = utils.eventually

	describe 'messaging', ->
		describe 'InProcServer', ->
			it 'should emit \'connection\' the next tick after client has connected', do ->
				spy = sinon.spy()
				server = new messaging.InProcServer
				new messaging.InProcClient().connect server
				server.on 'connection', spy
				eventually ->
					spy.calledOnce.should.be.true

			it 'should call listeners the next tick after the client side has emitted', do ->
				spy = sinon.spy()
				anotherSpy = sinon.spy()
				yetAnotherSpy = sinon.spy()
				server = new messaging.InProcServer
				client = new messaging.InProcClient
				client.connect server
				server.on 'connection', (socket) ->
					socket.on 'myEvent', spy
					socket.once 'myEvent', anotherSpy
					socket.on 'myAnotherEvent', yetAnotherSpy
				client.on 'connect', ->
					client.emit 'myEvent', 'a', 'b', 'c'
					client.emit 'myEvent', 'd', 'e'
				eventually ->
					spy.calledTwice.should.be.true
					spy.calledWith('a', 'b', 'c').should.be.true
					spy.calledWith('d', 'e').should.be.true
					anotherSpy.calledOnce.should.be.true
					yetAnotherSpy.callCount.should.equal 0

		describe 'InProcClient', ->
			it 'should emit \'connect\' the next tick after connected', do ->
				spy = sinon.spy()
				server = new messaging.InProcServer
				client = new messaging.InProcClient
				client.connect server
				client.on 'connect', spy
				eventually ->
					spy.calledOnce.should.be.true

			it 'should call listeners the next tick after the server side has emitted', do ->
				spy = sinon.spy()
				anotherSpy = sinon.spy()
				yetAnotherSpy = sinon.spy()
				server = new messaging.InProcServer
				client = new messaging.InProcClient
				client.connect server
				server.on 'connection', (socket) ->
					socket.emit 'myEvent', 'a', 'b', 'c'
					socket.emit 'myEvent', 'd', 'e'
				client.on 'myEvent', spy
				client.once 'myEvent', anotherSpy
				client.on 'myAnotherEvent', yetAnotherSpy
				eventually ->
					spy.calledTwice.should.be.true
					spy.calledWith('a', 'b', 'c').should.be.true
					spy.calledWith('d', 'e').should.be.true
					anotherSpy.calledOnce.should.be.true
					yetAnotherSpy.callCount.should.equal 0
)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @sinon? then @sinon else require('sinon')),
	(if @utils? then @utils else require '../src/utils'),
	(if @messaging? then @messaging else require '../src/messaging')
)
