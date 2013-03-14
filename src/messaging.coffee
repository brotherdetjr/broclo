((exports, EventEmitter, utils) ->

	NotImplementedError = utils.NotImplementedError
	nextTick = utils.nextTick

	###
	Interfaces to implement (eg. basing on Socket.IO http://socket.io)
	###

	class Server
		constructor: ->

		# 'connection' event callback should take Socket instance as an argument
		on: -> throw new NotImplementedError

	class Client
		constructor: ->

		# server - object representing the server
		#	given client can connect to
		# Returns Socket instance
		connect: (server) -> throw new NotImplementedError

	###
	In-process messaging for testing purposes
	###

	class InProcServer extends Server
		constructor: ->

	utils.mixin InProcServer, EventEmitter

	class InProcClient extends Client
		constructor: ->

		# For the in-process communication
		# connect accepts InProcServer instance as
		# a server arg
		connect: (server) ->
			socket = new InProcSocket
			oppositeSocket = new InProcSocket socket
			socket.oppositeSocket = oppositeSocket
			nextTick -> server.emit 'connection', oppositeSocket
			nextTick -> socket.eventEmitter.emit 'connect'
			socket

	class InProcSocket
		constructor: (@oppositeSocket) ->
			@eventEmitter = new EventEmitter

		emit: ->
			args = arguments
			nextTick =>
				@oppositeSocket.eventEmitter.emit.apply @oppositeSocket.eventEmitter, args

		on: (event, listener) ->
			@eventEmitter.on event, listener

		once: (event, listener) ->
			@eventEmitter.once event, listener

	exports.Server = Server
	exports.Client = Client
	exports.InProcServer = InProcServer
	exports.InProcClient = InProcClient

)(
	if exports? then exports else @messaging = {},
	(if @EventEmitter? then @EventEmitter else require('events').EventEmitter),
	(if @utils? then @utils else require './utils')
)
