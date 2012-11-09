/*
 * Parser - A math parser
 * 
 * Ethan Ransom - derethanhausen [at] gmail.com
*/

// library for data structures
using Gee;

// vala error handling
errordomain MathError {
  MALFORMED_EXPRESSION,
  DIVISION_BY_ZERO
}

// some usefull extesions to the Gee strutures
class AdvancedList<G> : ArrayList<G> {
  public G pop () {
    G item = this.last ();
    this.remove (item);
    return item;
  }

  public G dequeue () {
    G item = this.first ();
    this.remove (item);
    return item;
  }
}

class TokenList : AdvancedList<Token> {}
class OperandList : AdvancedList<Operand> {}


enum TokenType {
  NUMBER,
  OPERATOR,
  RIGHT_PAREN,
  LEFT_PAREN;

  public string to_string () {
      switch (this) {
          case NUMBER:
              return "Number";

          case OPERATOR:
              return "Operator";

          case RIGHT_PAREN:
              return "RightParen";

          case LEFT_PAREN:
              return "LeftParen";

          default:
              assert_not_reached ();
      }
  }
}

[Compact]
class Token : Object {
  public TokenType type;
  public string val;

  public Token(TokenType type, string val) {
    this.type = type;
    this.val = val;
  }

  public string to_string() {
    return "%s(\"%s\")".printf (this.type.to_string (), this.val);
  }

  public int get_precedence() {
    if (this.type != TokenType.OPERATOR)
      assert_not_reached();

    switch (this.val) {
      case "+":
      case "-":
        return 2;

      case "*":
      case "/":
        return 3;

      case "^":
        return 4;

      default:
        assert_not_reached();
    }
  }
}

// the numerical equivalent of number tokens
[Compact]
class Operand : Object {
  public double val;

  public Operand (string val) {
    this.val = double.parse(val);
  }

  public Operand.from_double (double val) {
    this.val = val;
  }

  public double perform_operation (string operator, Operand operand) {
    // stdout.printf ("Performing \"%s\" operation on %f, %f\n", operator, this.val, operand.val);
    switch (operator) {
    case "+":
      return this.val + operand.val;
    case "-":
      return this.val - operand.val;
    case "*":
      return this.val * operand.val;
    case "/":
      return this.val / operand.val;
    case "^":
      return Math.pow(this.val, operand.val); 
    default:
      assert_not_reached ();
    }
  }

  public string to_string () {
    return this.val.to_string();
  }
}

// most of the action happens here
// singleton, just beacuase
class Parser : Object {
  // print debug messages
  public static bool print_debug = false;

  static bool is_number (string input) {
    return Regex.match_simple (@"^(\\d)", input);
  }

  static bool is_operator (string input) {
    // return Regex.match_simple (@"(+|-|*|/)", input);
    return ("+" in input || "-" in input || "*" in input || "/" in input || "^" in input);
  }

  static void print_list(TokenList list) {
    for (int i = 0; i < list.size; i++) {
      stdout.printf("%s\n", list.get(i).to_string () );
    } 
  }

  // creates tokens out of input string
  static TokenList tokenize_string (string input) {
    int pointer = 0;
    var list = new TokenList ();

    for (int i = 0; i<input.length; i++) {
      string c = input.substring (pointer, 1);
      pointer++;

      if (c == " ")
        continue;

      if (is_number(c) || c == ".") {
        // handle multi digit numbers
        if (list.size > 0) {
          Token last = list.last();
           if (last.type == TokenType.NUMBER || last.val == ".") {
            list.remove( last );
            c = last.val + c;
          }
        }

        list.add( new Token (TokenType.NUMBER, c) );
      } else if (is_operator (c)) {
        list.add( new Token (TokenType.OPERATOR, c) );      
      } else if (c == "(") {
        // handle implicit multiplication, e.g. 4(3)
        if (list.size > 0 && list.last().type == TokenType.NUMBER) {
          if (print_debug)
            stdout.printf ("Assuming multiplication between %s and LeftParen(\"(\")\n", list.last().to_string());

          // insert implied multiply operator
          list.add (new Token (TokenType.OPERATOR, "*"));
        }

        list.add (new Token (TokenType.LEFT_PAREN, c));
      } else if (c == ")") {
        list.add (new Token (TokenType.RIGHT_PAREN, c));
      } else {
        // stdout.printf ("Unknown token: %s\n", c);
      }
    }
    if (print_debug) {
      print_list (list);

      stdout.printf ("Lexical Analysis Complete--%d token(s)\n", list.size);
    }

    return list;
  }

  // converts into post-fix notation
  // http://en.wikipedia.org/wiki/Reverse_Polish_notation
  static TokenList parse (TokenList list) {
    if (print_debug) 
      stdout.printf ("\nConverting Expression to Postfix...\n");

    var out_queue = new TokenList ();
    var operator_stack = new TokenList ();

    // implement shunting yard algorithim here
    while (list.size > 0) {
      var token = list.first ();
      var type = token.type;

      if (type == TokenType.NUMBER) {
        out_queue.add (list.dequeue ());
      } else if (type == TokenType.OPERATOR) {
        if (print_debug)
          stdout.printf("For operator %s\n", token.to_string());
        
        while (operator_stack.size > 0
          && operator_stack.last().type == TokenType.OPERATOR 
          && operator_stack.last().get_precedence() > token.get_precedence()) {
          if (print_debug)
            stdout.printf("\tPopping %s\n", operator_stack.last().to_string());
          out_queue.add(operator_stack.pop());
        }
        if (print_debug)
          stdout.printf("\tPushing %s\n", list.last().to_string());
        operator_stack.add(list.dequeue());
      } else if (type == TokenType.LEFT_PAREN) {
        operator_stack.add (list.dequeue ());
      } else if (type == TokenType.RIGHT_PAREN) {
        while (operator_stack.last().type != TokenType.LEFT_PAREN) {
          out_queue.add (operator_stack.pop ());

          if (operator_stack.size < 1) {
            stdout.printf ("ERROR: MISMATCHED PARENTHESIS");
            assert_not_reached ();
          }
        }

        // get rid of the parenthesis (both right and left)
        operator_stack.pop ();
        list.dequeue ();
      }
    }

    // remove any remaining operators on the operator stack
    while (operator_stack.size > 0)
      out_queue.add (operator_stack.pop ());

    if (print_debug) {
      print_list (out_queue);
      stdout.printf ("Postfix Conversion Complete--%d token(s)\n\n", out_queue.size);
    }

    return out_queue;
  }

  // simple stack-based post-fix evaluator
  static double interpret (TokenList tokens) throws MathError {
    var operands = new OperandList();
    if (print_debug) 
      stdout.printf ("Evaluating expression...\n");

    while (tokens.size > 0) {
      // do stuff
      var token = tokens.dequeue();

      if (token.type == TokenType.OPERATOR) {
        Operand operand_1 = operands.pop ();
        Operand operand_2 = operands.pop ();
        double result = operand_2.perform_operation (token.val, operand_1);
        var operand = new Operand.from_double (result);
        operands.add (operand);
      } else if (token.type == TokenType.NUMBER) {
        var operand = new Operand (token.val);
        if (print_debug)
          stdout.printf ("%s -> operand stack\n", operand.to_string());
        operands.add (operand);
      }
    }

    if (operands.size != 1) // something went wrong
      assert_not_reached ();
    
    if (print_debug)
      stdout.printf ("Evaluation Complete\n");
    return operands.first().val;
  }

  // chains the above three methods to do something awesome!
  public static double evaluate (string input) {
    var tokens = tokenize_string (input);
    var postfix_tokens = parse (tokens);
    double result = interpret (postfix_tokens);
    
    if (print_debug)
      stdout.printf("\nResult of Evaluation: %f\n", result);
    
    return result;
  }
}

// used in interactive mode
// TODO: variables?
public class MathShell {
  public void loop() {
    while (true) {
      stdout.printf(">");
      string? exp = stdin.read_line();
      if (exp == null || exp == "")
        continue;

      if (exp == "exit")
        break;

      double result = Parser.evaluate(exp);
      stdout.printf("%f\n", result);
    }
  }
}

public class Program {
  // bit too much?
  enum ExitCodes {
    SUCCESS,
    PROGRAM_ERROR,
    MATH_ERROR
  }

  static bool debug = false;
  static bool shell = false;

  const OptionEntry[] options = {
    {"debug", 'd', 0, OptionArg.NONE, ref debug, "Print debug messages", null},
    {"shell", 's', 0, OptionArg.NONE, ref shell, "Enter interactive shell", null},
    { null }
  };

  public static int main (string[] args) {
    // arguments parsing
    try {
      var opt = new OptionContext("string escaped expressions (\"2 + 2\")");
      opt.set_help_enabled(true);
      opt.add_main_entries(options, null);
      opt.parse(ref args);
    } catch (OptionError e) {
      stderr.printf("Error: %s\n", e.message);
      stderr.printf("Run '%s --help' to see a full list of available options\n", args[0]);
      return ExitCodes.PROGRAM_ERROR;
    }

    if (shell) {
      stdout.printf("Entering interactive shell\n");
      stdout.printf("Type 'exit' to exit\n");

      var sh = new MathShell();
      sh.loop();
      return ExitCodes.SUCCESS;
    }

    if (args.length < 2) {
      stderr.printf("No expressions given\n");
      stderr.printf("Run '%s --help' for usage\n", args[0]);
      return ExitCodes.PROGRAM_ERROR;
    }

    Parser.print_debug = debug;

    // begin actual parsing
    try {
      for (int i = 1; i<args.length; i++) {
        stdout.printf("%f\n",

          Parser.evaluate (args[i])
        );
      }
    } catch (MathError e) {
      stderr.printf("Error: %s\n", e.message);
      return ExitCodes.MATH_ERROR;
    }

    return ExitCodes.SUCCESS;
  }
}
