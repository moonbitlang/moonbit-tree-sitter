///|
pub enum Quantifier {
  ZeroOrOne
  ZeroOrMore
  One
  OneOrMore
} derive(Eq, ToJson)

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
  Symbol(String)
  String(String)
  Anchor
  Capture(String)
  Comment(String)
  Newline
  Predicate(String)
  Directive(String)
} derive(Eq, ToJson)

///|
pub impl Show for Atom with output(self : Atom, logger : &Logger) -> Unit {
  match self {
    Symbol(symbol) => logger.write_string(symbol)
    String(string) => logger.write_string(string.escape())
    Anchor => logger.write_char('.')
    Capture(capture) => {
      logger.write_char('@')
      logger.write_string(capture)
    }
    Comment(comment) => {
      logger.write_char(';')
      logger.write_string(comment)
    }
    Newline => logger.write_char('\n')
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
struct List {
  open : Char
  close : Char
  list : Array[Sexp]
  mut quantifier : Quantifier
} derive(Eq, Show, ToJson)

///|
pub fn List::new(
  open~ : Char = '(',
  list : Array[Sexp],
  close~ : Char = ')',
  quantifier~ : Quantifier = One
) -> List {
  List::{ open, list, close, quantifier }
}

///|
pub enum Sexp {
  Atom(Atom)
  Pair(String, Sexp)
  List(List)
} derive(Eq, Show)

///|
pub fn Sexp::list(
  open~ : Char = '(',
  list : Array[Sexp],
  close~ : Char = ')',
  quantifier~ : Quantifier = One
) -> Sexp {
  Sexp::List(List::new(open~, list, close~, quantifier~))
}

///|
pub impl ToJson for Sexp with to_json(self : Sexp) -> Json {
  match self {
    Atom(atom) => atom.to_json()
    Pair(key, value) => {
      let object = {}
      object[key] = value.to_json()
      Json::object(object)
    }
    List(list) => list.to_json()
  }
}
