express = require 'express'
app = express()
server = require('http').createServer app
io = require('socket.io').listen server
coffeemiddle = require 'coffee-middle'

port = if process.argv[2]? then process.argv[2] else 80
dones = process.argv[3]

server.listen port

app
	.get('/', (req, res) -> res.sendfile __dirname + '/index.html')
	.use('/', express.static __dirname + '/')
	.use(coffeemiddle(
		src: __dirname + '/../'
		writeFileToPublicDir: false
	))
	.use(coffeemiddle(
		src: __dirname + '/../../src/'
		writeFileToPublicDir: false
	))

io.sockets.on 'connection', (socket) ->
	socket.on 'done', ->
		if dones?
			dones--
			console.log 'Dones left: ' + dones
			if dones == 0
				process.exit()
				

console.log 'Started test server on port ' + port
if dones?
	console.log 'Dones left: ' + dones
else
	console.log 'Will ignore dones'
