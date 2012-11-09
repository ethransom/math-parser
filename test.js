var expect = require('chai').expect;
var spawn = require('child_process').spawn;

describe('Parser', function(){
	function parse(exp, done) {
		var parser = spawn('./parser', [exp]);

		parser.stdout.on('data', function (data) {
			var result = parseFloat(
				data.toString().trim()
			);
			done(result);
		});

		parser.on('exit', function (code) {
			if (code != 0)
				throw new Error("Parser terminated with code " + code)
		});
	}

	function assert_parse(exp, answer, done) {
		parse(exp, function(result) {
			expect(result).to.equal(answer);
			done();
		})
	}
	var expressions = [
		// simple operations
		['2 + 2',4],
		['5 - 3',2],
		['5 * 6',30],
		['12 / 4',3],
		// negatives
		['5 - 10',-5],
		// decimals
		['2.07 + 3.13',5.20],
		['6.39 - 4.27',2.12],
		// exponents
		['2^2',4],
		['8^(1/3)',2],
		['8^(2/3)',4],
		['4^.5',2],
		// order of operations
		['5 * 5 + 2',27],
		['2 + 3 * 2',8],
		['5 * 5 - 2',23],
		['2 - 3 * 2',-4],
		['5 / 5 + 2',3],
		['2 + 6 / 3',4],
		['5 / 5 - 2',-1],
		['2 - 6 / 3',0],
		['3 ^ 2 - 2', 7],
		['4 + 2 ^ 3',12],
		['5 ^ 2 / 5',5],
		['34 - 8 ^ 2',-30]
	];

	expressions.forEach(function (expression) {
		it('evaluates ' + expression[0] + ' correctly', function(done) {
			assert_parse(expression[0], expression[1], done);
		})
	});
})