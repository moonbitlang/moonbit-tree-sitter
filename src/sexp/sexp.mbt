///|
pub enum Quantifier {
  ZeroOrOne
  ZeroOrMore
  One
  OneOrMore
} derive(Eq)

///|
pub fn Quantifier::from_char(char : Char) -> Quantifier raise SexpError {
  match char {
    '+' => OneOrMore
    '*' => ZeroOrMore
    '?' => ZeroOrOne
    char => raise InvalidQuantifier(char)
  }
}

///|
pub impl Show for Quantifier with output(self : Quantifier, logger : &Logger) -> Unit {
  match self {
    ZeroOrMore => logger.write_char('*')
    ZeroOrOne => logger.write_char('?')
    One => ()
    OneOrMore => logger.write_char('+')
  }
}

///|
pub enum Atom {
  Field(String)
  Symbol(String)
  String(String)
  Narrow(String)
  Anchor
  Capture(String)
  Comment(String)
  Predicate(String)
  Directive(String)
} derive(Eq)

///|
impl ToJson for Atom with to_json(self : Atom) -> Json {
  self.to_string().to_json()
}

///|
pub impl Show for Atom with output(self : Atom, logger : &Logger) -> Unit {
  match self {
    Field(name) => {
      logger.write_string(name)
      logger.write_char(':')
    }
    Symbol(symbol) => logger.write_string(symbol)
    String(string) => logger.write_string(string.escape())
    Narrow(narrow) => {
      logger.write_char('@')
      logger.write_string(narrow)
      logger.write_char(':')
    }
    Anchor => logger.write_char('.')
    Capture(capture) => {
      logger.write_char('@')
      logger.write_string(capture)
    }
    Comment(comment) => {
      logger.write_char(';')
      logger.write_string(comment)
    }
    Predicate(predicate) => {
      logger.write_char('#')
      logger.write_string(predicate)
      logger.write_char('?')
    }
    Directive(directive) => {
      logger.write_char('#')
      logger.write_string(directive)
      logger.write_char('!')
    }
  }
}

///|
pub enum Delimiter {
  Bracket
  Parenthesis
  Brace
} derive(Eq, Show)

///|
fn Delimiter::open(self : Delimiter) -> Char {
  match self {
    Bracket => '['
    Parenthesis => '('
    Brace => '{'
  }
}

///|
fn Delimiter::close(self : Delimiter) -> Char {
  match self {
    Bracket => ']'
    Parenthesis => ')'
    Brace => '}'
  }
}

///|
pub enum Sexp {
  Atom(Atom)
  List(Array[Sexp], delimiter~ : Delimiter, mut quantifier~ : Quantifier)
} derive(Eq)

///|
pub fn Sexp::list(
  list : Array[Sexp],
  delimiter~ : Delimiter = Parenthesis,
  quantifier~ : Quantifier = One,
) -> Sexp {
  Sexp::List(list, delimiter~, quantifier~)
}

///|
pub impl ToJson for Sexp with to_json(self : Sexp) -> Json {
  match self {
    Atom(atom) => atom.to_json()
    List(list, ..) => list.to_json()
  }
}

///|
pub impl Show for Sexp with output(self : Sexp, logger : &Logger) -> Unit {
  match self {
    Atom(atom) => atom.output(logger)
    List(list, delimiter~, quantifier~) => {
      logger.write_char(delimiter.open())
      for i, sexp in list {
        sexp.output(logger)
        if i < list.length() - 1 {
          logger.write_char(' ')
        }
      }
      logger.write_char(delimiter.close())
      if quantifier != One {
        logger.write_object(quantifier)
      }
    }
  }
}
