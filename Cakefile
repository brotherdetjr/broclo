open = require 'open'
{spawn} = require 'child_process'

browsers = ['chrome', 'firefox']
port = 80

task 'test', 'Run tests', ->
	ext = if process.platform == 'win32' then '.cmd' else ''
	spawn 'mocha' + ext, [], stdio: 'inherit'
	spawn 'coffee' + ext, ['./test/browser/server.coffee', port, browsers.length], detached: true
	for browser in browsers
		open 'http://localhost:' + port, browser
