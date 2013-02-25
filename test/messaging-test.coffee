((should, messaging) ->

	describe 'messaging.InProcServer', ->
		it 'should emit \'connection\' the next tick after client has connected', (done) ->
			server = new messaging.InProcServer
			new messaging.InProcClient().connect server
			server.on 'connection', (socket) ->
				should.exist socket.on
				should.exist socket.once
				should.exist socket.emit
				done()

	describe 'messaging.InProcClient', ->
		it 'should emit \'connect\' the next tick after connected', (done) ->
			server = new messaging.InProcServer
			client = new messaging.InProcClient
			client.connect server
			client.on 'connect', -> done()

		it 'should emit event the next tick after the server side has emitted', (done) ->
			server = new messaging.InProcServer
			client = new messaging.InProcClient
			client.connect server
			server.on 'connection', (socket) ->
				socket.emit 'myEvent', 'a', 'b', 'c'
			client.on 'myEvent', (a, b, c) ->
				a.should.equal 'a'
				b.should.equal 'b'
				c.should.equal 'c'
				done()
)(
	(if @chai? then @chai.should() else require('chai').should()),
	(if @messaging? then @messaging else require '../src/messaging')
)
