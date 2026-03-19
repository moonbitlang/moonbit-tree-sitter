///|
pub suberror SexpError {
  UnrecognizedCharacter(StringView)
  UnterminatedString(StringView)
  UnterminatedList(StringView)
  ExtraContent(ArrayView[Sexp])
  InvalidPairKey(StringView)
  InvalidQuantifier(Char)
  InvalidCommand(StringView)
} derive(Show)

///|
fn parse_list(
  source : StringView,
  sexp : Array[Sexp],
) -> StringView raise SexpError {
  fn parse_string(
    source : StringView,
    string : StringBuilder,
    quote : Char,
  ) -> StringView raise SexpError {
    loop source {
      ['\\', '\\', .. source] => {
        string.write_char('\\')
        continue source
      }
      ['\\', char, .. source] if char == quote => {
        string.write_char(char)
        continue source
      }
      [char, .. source] if char == quote => return source
      [char, .. source] => {
        string.write_char(char)
        continue source
      }
      [.. source] => raise SexpError::UnterminatedString(source)
    }
  }

  fn parse_symbol(source : StringView, symbol : StringBuilder) -> StringView {
    loop source {
      ['a'..<'z' | 'A'..<'Z' | '0'..<'9' | '_' as char, .. source] => {
        symbol.write_char(char)
        continue source
      }
      [.. source] => return source
    }
  }

  fn parse_comment(source : StringView, comment : StringBuilder) -> StringView {
    loop source {
      ['\n', ..] as source => return source
      [char, .. source] => {
        comment.write_char(char)
        continue source
      }
      [.. source] => return source
    }
  }

  loop source {
    [' ' | '\t' | '\n' | '\r', .. source] => continue source
    ['\'' | '"' as quote, .. source] => {
      let string = StringBuilder::new()
      let source = parse_string(source, string, quote)
      sexp.push(Atom(String(string.to_string())))
      continue source
    }
    ['.', .. source] => {
      sexp.push(Atom(Anchor))
      continue source
    }
    ['(', .. source] => {
      let list = []
      let sexp_list = Sexp::List(list, delimiter=Parenthesis, quantifier=One)
      guard sexp_list is (List(_, ..) as sexp_list)
      sexp.push(sexp_list)
      match parse_list(source, list) {
        [')', '+' | '?' | '*' as quantifier, .. source] => {
          sexp_list.quantifier = Quantifier::from_char(quantifier)
          continue source
        }
        [')', .. source] => continue source
        [.. source] => raise SexpError::UnterminatedList(source)
      }
    }
    ['[', .. source] => {
      let list = []
      let sexp_list = Sexp::List(list, delimiter=Bracket, quantifier=One)
      guard sexp_list is (List(_, ..) as sexp_list)
      sexp.push(sexp_list)
      match parse_list(source, list) {
        [']', '+' | '?' | '*' as quantifier, .. source] => {
          sexp_list.quantifier = Quantifier::from_char(quantifier)
          continue source
        }
        [']', .. source] => continue source
        [.. source] => raise SexpError::UnterminatedList(source)
      }
    }
    ['{', .. source] => {
      let list = []
      let sexp_list = Sexp::List(list, delimiter=Brace, quantifier=One)
      guard sexp_list is (List(_, ..) as sexp_list)
      sexp.push(sexp_list)
      match parse_list(source, list) {
        ['}', '+' | '?' | '*' as quantifier, .. source] => {
          sexp_list.quantifier = Quantifier::from_char(quantifier)
          continue source
        }
        ['}', .. source] => continue source
        [.. source] => raise SexpError::UnterminatedList(source)
      }
    }
    ['#', .. source] => {
      let command = StringBuilder::new()
      match parse_symbol(source, command) {
        ['?', .. source] => {
          sexp.push(Atom(Predicate(command.to_string())))
          continue source
        }
        ['!', .. source] => {
          sexp.push(Atom(Directive(command.to_string())))
          continue source
        }
        [':', ..] => raise SexpError::InvalidPairKey(command.to_string())
        [.. source] => raise SexpError::InvalidCommand(source)
      }
    }
    ['@', .. source] => {
      let capture = StringBuilder::new()
      match parse_symbol(source, capture) {
        [':', .. source] => {
          sexp.push(Atom(Narrow(capture.to_string())))
          continue source
        }
        [.. source] => {
          sexp.push(Atom(Capture(capture.to_string())))
          continue source
        }
      }
    }
    [';', .. source] => {
      let comment = StringBuilder::new()
      let source = parse_comment(source, comment)
      sexp.push(Atom(Comment(comment.to_string())))
      continue source
    }
    ['a'..<'z' | 'A'..<'Z' | '0'..<'9' | '_' as char, .. source] => {
      let symbol = StringBuilder::new()
      symbol.write_char(char)
      match parse_symbol(source, symbol) {
        [':', .. source] => {
          sexp.push(Atom(Field(symbol.to_string())))
          continue source
        }
        [.. source] => {
          sexp.push(Atom(Symbol(symbol.to_string())))
          continue source
        }
      }
    }
    [.. source] => return source
  }
}

///|
pub fn Sexp::parse(source : StringView) -> Sexp raise SexpError {
  let list = []
  let source = parse_list(source, list)
  if source is [_, ..] {
    raise SexpError::UnrecognizedCharacter(source)
  }
  match list {
    [sexp] => return sexp
    [_, .. list] => raise SexpError::ExtraContent(list)
    [] => raise SexpError::UnrecognizedCharacter(source)
  }
}

///|
pub fn parse(source : StringView) -> Array[Sexp] raise SexpError {
  let list = []
  let source = parse_list(source, list)
  match source {
    [_, ..] => raise SexpError::UnrecognizedCharacter(source)
    [] => return list
  }
}
