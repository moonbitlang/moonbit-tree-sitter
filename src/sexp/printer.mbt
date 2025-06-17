///|
pub fn pretty_to(list : Array[Sexp], result : Array[Sexp]) -> Unit {
  loop (true, list[:]) {
    (first, list) =>
      match (first, list) {
        (first, [Atom(Newline), Atom(Comment(_)) as comment, .. list]) => {
          if not(first) {
            result.push(Atom(Newline))
          }
          result.push(comment)
          result.push(Atom(Newline))
          continue (true, list)
        }
        (first, [Atom(Newline), .. list]) => continue (first, list)
        (_, [Atom(Comment(_)) as comment, .. list]) => {
          result.push(comment)
          result.push(Atom(Newline))
          continue (true, list)
        }
        (_, [Atom(Capture(_)) as capture]) => {
          result.push(capture)
          break
        }
        (_, [Atom(Capture(_)) as capture, .. list]) => {
          result.push(capture)
          result.push(Atom(Newline))
          continue (true, list)
        }
        (first, [sexp, .. list]) => {
          if not(first) {
            result.push(Atom(Newline))
          }
          result.push(sexp.pretty())
          continue (false, list)
        }
        (_, []) => break
      }
  }
}

///|
pub fn Sexp::pretty(self : Sexp) -> Sexp {
  match self {
    Atom(_) => self
    Pair(key, value) => return Pair(key, value.pretty())
    List({ open, list, close, quantifier }) => {
      let result = []
      pretty_to(list, result)
      return Sexp::list(open~, result, close~, quantifier~)
    }
  }
}

///|
pub fn pretty(list : Array[Sexp]) -> Array[Sexp] {
  let result = []
  pretty_to(list, result)
  return result
}

///|
pub fn print_to(
  list : Array[Sexp],
  logger : &Logger,
  indent~ : Int = 0
) -> Unit {
  loop list[:] {
    [Atom(Newline), Atom(Comment(_)) as comment, .. list] => {
      logger.write_char('\n')
      for i in 0..<indent {
        logger.write_char(' ')
      }
      comment.print_to(logger, indent~)
      continue list
    }
    [Atom(Newline)] => {
      logger.write_char('\n')
      for i in 0..<(indent - 1) {
        logger.write_char(' ')
      }
    }
    [Atom(Newline), Atom(Newline), ..] as list => {
      logger.write_char('\n')
      continue list[1:]
    }
    [Atom(Newline), .. list] => {
      logger.write_char('\n')
      for i in 0..<indent {
        logger.write_char(' ')
      }
      continue list
    }
    [sexp] => {
      sexp.print_to(logger, indent~)
      break
    }
    [sexp, Atom(Newline), ..] as list => {
      sexp.print_to(logger, indent~)
      continue list[1:]
    }
    [sexp, .. list] => {
      sexp.print_to(logger, indent~)
      logger.write_char(' ')
      continue list
    }
    [] => break
  }
}

///|
pub fn print(list : Array[Sexp]) -> String {
  let buffer = StringBuilder::new()
  print_to(list, buffer)
  return buffer.to_string()
}

///|
pub fn Sexp::print_to(self : Sexp, logger : &Logger, indent~ : Int = 0) -> Unit {
  match self {
    Atom(atom) => logger.write_object(atom)
    Pair(key, value) => {
      logger.write_string(key)
      logger.write_string(": ")
      value.print_to(logger, indent=indent + key.length() + 2)
    }
    List({ open, list, close, quantifier }) => {
      logger.write_char(open)
      print_to(list, logger, indent=indent + 1)
      logger.write_char(close)
      logger.write_object(quantifier)
    }
  }
}

///|
test "print" {
  let sexp : Sexp = Sexp::list([
    Atom(Symbol("a")),
    Atom(String("b")),
    Pair("c", Sexp::list([Atom(Symbol("d")), Atom(String("e"))])),
  ])
  let buffer = StringBuilder::new()
  sexp.print_to(buffer)
  inspect(
    buffer,
    content=
      #|(a "b" c: (d "e"))
    ,
  )
}

///|
pub fn prettify(source : @string.View) -> @string.View raise SexpError {
  parse(source) |> pretty() |> print()
}
