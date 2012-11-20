var expect = require('chai').expect;
var spawn = require('child_process').spawn;

describe('Parser', function(){
	function Parse (exp, done) {
		this.exp = exp;
		this.messages = "";
		this.callback = done;
		this.exitCode = null;
		this.result = null;

		var that = this;

		var parser = spawn('./parser', [exp]);

		parser.stdout.on('data', function (data) {
			that.messages += data.toString();
		});

		parser.on('exit', function (code) {
			that.exit.call(that, code);
		});
	}
	Parse.prototype.exit = function (code) {
		this.exitCode = code;

		if (code == 0) {
			this.result = parseFloat(
				this.messages.trim()
			);
		}

		this.callback(this.result);
	}

	function assert_parse(exp, answer, done) {
		new Parse(exp, function(result) {
			expect(result).to.equal(answer);
			done();
		});
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
		['34 - 8 ^ 2',-30],
		// square brackets are identical to parens
		['[[4]]',4],
		['2 * [2 + 3]', 10],
		// adjacent multiplication
		['4(3)',12],
		['4(2(3))',24],
		['5(2*5+3)',65]
	];

	expressions.forEach(function (expression) {
		it('evaluates ' + expression[0] + ' correctly', function(done) {
			assert_parse(expression[0], expression[1], done);
		})
	});
})