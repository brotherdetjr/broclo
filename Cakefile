open = require 'open'
{spawn} = require 'child_process'

browsers = ['chrome', 'firefox']
port = 80
#killserver = true

task 'test', 'Run tests', ->
	ext = if process.platform == 'win32' then '.cmd' else ''
	spawn 'mocha' + ext, [], stdio: 'inherit'
	if browsers? and browsers.length > 0
		opts = ['./test/browser/server.coffee', if port? then port else 80]
		if not killserver? or killserver then opts.push browsers.length
		spawn 'coffee' + ext, opts, detached: true
		for browser in browsers
			open 'http://localhost:' + port, browser
