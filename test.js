var expect = require('expect.js');
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

	describe('basic arithmetic', function(){
		it('adds numbers correctly', function(done){
			parse('2 + 2', function(result) {
				expect(result).to.be(4);
				done();
			})
		})

		it('subtracts numbers correctly', function(done){
			parse('5 - 3', function(result) {
				expect(result).to.be(2);
				done();
			})
		})

		it('multiplies numbers correctly', function(done){
			parse('5 * 6', function(result) {
				expect(result).to.be(30);
				done();
			})
		})

		it('adds numbers correctly', function(done){
			parse('12 / 4', function(result) {
				expect(result).to.be(3);
				done();
			})
		})

		it('can handle negative answers', function(done) {
			parse('5 - 10', function(result) {
				expect(result).to.be(-5);
				done();
			})
		})
	})

	describe('floating point arithmetic', function() {
		it('adds floats', function(done){
			parse('2.07 + 3.13', function(result) {
				expect(result).to.be(5.20);
				done();
			})
		})

		it('subtracts floats', function(done){
			parse('2.07 - 5.28', function(result) {
				expect(result).to.be(-3.21);
				done();
			})
		})
	})

	describe('exponents', function() {
		it('handles exponents correctly', function(done) {
			parse('2^2', function (result) {
				expect(result).to.be(4);
				done();
			})
		})

		it('handles rational exponents correctly', function(done) {
			parse('8^(1/3)', function (result) {
				expect(result).to.be(2);
				parse('8^(2/3)', function (result) {
					expect(result).to.be(4);
					done();
				})
			})
		})
	})

	describe('order of operations', function() {
		it('puts multiply before add', function(done) {
			parse('5 * 5 + 2', function (result) {
				expect(result).to.be(27);
				parse('2 + 3 * 2', function (result) {
					expect(result).to.be(8);
					done();
				})
			})
		})

		it('puts multiply before subtract', function(done) {
			parse('5 * 5 - 2', function (result) {
				expect(result).to.be(23);
				parse('2 - 3 * 2', function (result) {
					expect(result).to.be(-4);
					done();
				})
			})
		})

		it('puts divide before add', function(done) {
			parse('5 / 5 + 2', function (result) {
				expect(result).to.be(3);
				parse('2 + 6 / 3', function (result) {
					expect(result).to.be(4);
					done();
				})
			})
		})

		it('puts divide before subtract', function(done) {
			parse('5 / 5 - 2', function (result) {
				expect(result).to.be(-1);
				parse('2 - 6 / 3', function (result) {
					expect(result).to.be(0);
					done();
				})
			})
		})

		it('puts exponents before addition and subtraction', function(done) {
			parse('3 ^ 2 - 2', function (result) {
				expect(result).to.be(7);
				parse('4 + 2 ^ 3', function (result) {
					expect(result).to.be(12);
					done();
				})
			})
		})

		it('puts exponents before multiplication and division', function(done) {
			parse('5 ^ 2 / 5', function (result) {
				expect(result).to.be(5);
				parse('34 - 8 ^ 2', function (result) {
					expect(result).to.be(-30);
					done();
				})
			})
		})
	})

})