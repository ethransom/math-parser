all: parser test

parser:
	valac --pkg gee-1.0  -X -lm parser.vala

clean:
	rm -f parser

test:
	mocha test.js