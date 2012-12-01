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

class TokenList : AdvancedList<Token> {
  public string to_string () {
    string output = "";

    while (this.size > 0) {
      var token = this.dequeue();
      output += token.val;
    }

    return output;
  }
}


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
      case "%":
        return 3;

      case "^":
        return 4;

      default:
        assert_not_reached();
    }
  }

  // placeholder
  public static double operate (string operation, double a, double b) {
    if (Program.debug)
      stdout.printf ("Performing \"%s\" operation on %f, %f\n", operation, a, b);

    switch (operation) {
    case "+":
      return a + b;
    case "-":
      return a - b;
    case "*":
      return a * b;
    case "/":
      return a / b;
    case "%":
      return a % b;
    case "^":
      return Math.pow(a, b);
    default:
      assert_not_reached ();
    }
  }
}

class TreeNode : Object {
  public Token token;

  public TreeNode right = null;
  public TreeNode left = null;

  public string print (string input) {
    string output = input + this.token.to_string() + "\n";

    string prepend = input + "  ";

    if (this.right != null)
      output += this.right.print (prepend);

    if (this.left != null)
      output += this.left.print (prepend);

    return output;
  }

  public TreeNode (Token token) {
    this.token = token;
  }

  public bool append (TreeNode node) {
    if (Program.debug) stdout.printf("Trying to append %s to %s\n", node.token.to_string(), this.token.to_string());

    if (this.token.type == TokenType.NUMBER)
      return false;

    // this node has room, append somewhere
    if (this.right == null) {
      this.right = node;
      if (Program.debug) stdout.printf("Appending %s to right of %s\n", node.token.to_string(), this.token.to_string() );
      return true;
    } 

    if (this.right.token.type == TokenType.OPERATOR) {
      if (this.right.append (node)) {
        if (Program.debug) stdout.printf("Appending %s to %s (which is right of %s)\n", node.token.to_string(), this.right.token.to_string(), this.token.to_string() );
        return true;  // everything went well
      }
    }

    if (this.left == null) {
      this.left = node;
      if (Program.debug) stdout.printf("Appending %s to left of %s\n", node.token.to_string(), this.token.to_string() );
      return true;
    }

    if (this.left.token.type == TokenType.OPERATOR) {
      if (this.left.append (node)) {
        if (Program.debug) stdout.printf("Appending %s to %s (which is left of %s)\n", node.token.to_string(), this.left.token.to_string(), this.token.to_string() );
        return true;
      }
    }

    // this node is completely full
    if (Program.debug) stdout.printf("Could not append %s to %s\n", node.token.to_string(), this.token.to_string());
    return false;
  }

  public double evaluate () {
    if (this.token.type == TokenType.NUMBER)
      return double.parse(this.token.val);
    else // assume operator
      return Token.operate(this.token.val, this.left.evaluate(), this.right.evaluate());
  }
}

class SyntaxTree : Object {
  TreeNode root = null;

  public string to_string () {
    if (this.root == null) 
      return "";

    stdout.printf ("\nPrinting SyntaxTree: \n");
    return this.root.print("") + "\n";
  }

  public SyntaxTree () {
    stdout.printf("Construct\n");
  }

  public SyntaxTree.from_postfix (TokenList postfix_tokens) {
    if (Program.debug)
      stdout.printf("Constructing from post-fix\n");

    var working_node = this.root;

    while (postfix_tokens.size > 0) {
      var token = postfix_tokens.pop();
      
      if (Program.debug)
        stdout.printf("Popping %s\n", token.to_string());

      if (this.root == null) {
        this.root = new TreeNode (token);

        if (Program.debug)
          stdout.printf("Appending %s as root node\n", token.to_string());
      } else
        this.root.append (new TreeNode (token));

    }

    if (Program.debug)
      stdout.printf (this.to_string ());
  }

  public double evaluate () {
    return this.root.evaluate();
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
    return ("+" in input || "-" in input || "*" in input || "/" in input || "^" in input || "%" in input);
  }

  static bool is_left_paren (string input) {
    return (input == "(" || input == "[");
  }

  static bool is_right_paren (string input) {
    return (input == ")" || input == "]");
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
      } else if (is_left_paren (c)) {
        // handle implicit multiplication, e.g. 4(3)
        if (list.size > 0 && list.last().type == TokenType.NUMBER) {
          if (print_debug)
            stdout.printf ("Assuming multiplication between %s and LeftParen(\"(\")\n", list.last().to_string());

          // insert implied multiply operator
          list.add (new Token (TokenType.OPERATOR, "*"));
        }

        list.add (new Token (TokenType.LEFT_PAREN, c));
      } else if (is_right_paren (c)) {
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

  // chains the above three methods to do something awesome!
  public static double evaluate (string input) {
    var tokens = tokenize_string (input);
    var postfix_tokens = parse (tokens);
    
    var tree = new SyntaxTree.from_postfix (postfix_tokens);
    double result = tree.evaluate();
    
    if (print_debug)
      stdout.printf("\nResult of Evaluation: %f\n", result);
    
    return result;
  }

  public static TokenList to_postfix (string input) {
    var tokens = tokenize_string (input);
    var postfix_tokens = parse (tokens);

    return postfix_tokens;
  }
}

// used in interactive mode
// TODO: variables?
public class MathShell {
  // prints whole numbers without decimal places
  void print_number (double num) {
    double rounded = Math.round (num);

    if (num == rounded) {
      stdout.printf("%d\n", (int)num);
    } else {
      stdout.printf("%f\n", num);
    }
  }

  public void eval (string exp) {
    double result = Parser.evaluate(exp);
    print_number (result);
  }

  public void loop() {
    while (true) {
      stdout.printf(">");
      string? exp = stdin.read_line();
      if (exp == null || exp == "")
        continue;

      if (exp == "exit")
        break;

      eval(exp);
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

  public static bool debug = false;
  static bool shell = false;
  static bool print_postfix = false;
  static bool print_syntax_tree = false;

  const OptionEntry[] options = {
    {"debug", 'd', 0, OptionArg.NONE, ref debug, "Print debug messages", null},
    {"shell", 's', 0, OptionArg.NONE, ref shell, "Enter interactive shell", null},
    {"print_postfix", 'p', 0, OptionArg.NONE, ref print_postfix, "Convert expression(s) to postfix", null},
    {"print_syntax_tree", 't', 0, OptionArg.NONE, ref print_syntax_tree, "Print the syntax tree for the expression", null},
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

    if (print_postfix) {
      for (int i = 1; i<args.length; i++) {
        TokenList tokens = Parser.to_postfix (args[i]);
        stdout.printf ("%s\n", tokens.to_string ());
      }

      return ExitCodes.SUCCESS;
    }

    if (print_syntax_tree) {
      for (int i = 1; i<args.length; i++) {
        TokenList tokens = Parser.to_postfix (args[i]);
        var tree = new SyntaxTree.from_postfix (tokens);
        stdout.printf ("%s\n", tree.to_string ());
      }

      return ExitCodes.SUCCESS;
    }

    // begin actual parsing
    try {
      var shell = new MathShell();
      for (int i = 1; i<args.length; i++) {
        shell.eval (args[i]);
      }
    } catch (MathError e) {
      stderr.printf("Error: %s\n", e.message);
      return ExitCodes.MATH_ERROR;
    }

    return ExitCodes.SUCCESS;
  }
}
