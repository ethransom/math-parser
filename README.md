# Math Parser

----------

A mathmatical expression evaluator written in [vala](https://live.gnome.org/Vala). I wrote it mainly to learn about parsing, but may turn it into a more involved [CAS](http://en.wikipedia.org/wiki/Computer_algebra_system).

## Hacking

Tests are written in javascript. You will need [Mocha](http://visionmedia.github.com/mocha/) and [Chai](http://chaijs.com/). Install like so:

	$ npm install mocha -g
	$ npm install chai

 * __make test -B__ - Run the tests in `test.js`
 * __make parser -B__ - Build the parser
 * __make all -B__ - Build and test parser

Not supported on anything except linux (sorry, you're welcome to try it yourself).

## Using

Options:

`./parser expression(s) options`

 * `--debug` - Print extremely verbose messages about what is going on
 * `--shell` - Enter interactive shell mode

Examples:

	$ ./parser 2+2
	$ ./parser --shell
	Entering interactive shell
	Type 'exit' to exit
	>2 - 2
	0
	>exit
	$ ./parser --debug "4 + (5 - 12) * 34"
	<lots of output>

----------

> Copyright (c) 2012 Ethan Ransom. MIT Licensed.