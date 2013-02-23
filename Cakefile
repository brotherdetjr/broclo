open = require 'open'
{spawn} = require 'child_process'
CSON = require 'cson'

conf = CSON.parseFileSync 'testserver.cson'

task 'test', 'Run tests', ->
	ext = if process.platform == 'win32' then '.cmd' else ''
	spawn 'mocha' + ext, [], stdio: 'inherit'
	if conf.browsers? and conf.browsers.length > 0
		opts = ['./test/browser/server.coffee', if conf.port? then conf.port else 80]
		if not conf.killserver? or conf.killserver then opts.push conf.browsers.length
		spawn 'coffee' + ext, opts, detached: true
		for browser in conf.browsers
			open 'http://localhost:' + conf.port, browser
