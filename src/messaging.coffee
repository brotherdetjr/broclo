((exports, EventEmitter, utils) ->

	NotImplementedError = utils.NotImplementedError
	nextTick = utils.nextTick

	###
	Interfaces to implement (eg. basing on Socket.IO)
	###

	class Server
		constructor: ->

		on: -> throw new NotImplementedError

	class Client
		constructor: ->

		connect: -> throw new NotImplementedError

		on: (event, listener) -> throw new NotImplementedError

		once: (event, listener) -> throw new NotImplementedError

		emit: -> throw new NotImplementedError

	###
	In-process messaging for testing purposes
	###

	class InProcServer extends Server
		constructor: ->

		@ClientSocket: class
			constructor: (@client) ->
				@eventEmitter = new EventEmitter

			emit: ->
				args = arguments
				nextTick =>
					@client.eventEmitter.emit.apply @client.eventEmitter, args

			on: (event, listener) ->
				@eventEmmiter.on event, listener

			once: (event, listener) ->
				@eventEmmiter.once event, listener

	utils.mixin InProcServer, EventEmitter

	class InProcClient extends Client
		constructor: ->
			@eventEmitter = new EventEmitter

		connect: (server) ->
			@clientSocket = new InProcServer.ClientSocket @
			nextTick =>
				server.emit 'connection', @clientSocket
			nextTick =>
				@eventEmitter.emit 'connect'

		on: (event, listener) ->
			@eventEmitter.on event, listener

		once: (event, listener) ->
			@eventEmitter.once event, listener

		emit: ->
			args = arguments
			nextTick =>
				@clientSocket.eventEmitter.emit.apply @clientSocket.eventEmitter, args

	exports.Server = Server
	exports.Client = Client
	exports.InProcServer = InProcServer
	exports.InProcClient = InProcClient

)(
	if exports? then exports else @messaging = {},
	(if @EventEmitter? then @EventEmitter else require('events').EventEmitter),
	(if @utils? then @utils else require './utils')
)
