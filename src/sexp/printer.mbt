///|
pub fn print_to(
  list : ArrayView[Sexp],
  logger : &Logger,
  indent~ : Int = 0,
) -> Unit {
  loop list {
    [] => ()
    [Atom(Comment(_)) as sexp] => {
      sexp.print_to(logger, indent~)
      logger.write_char('\n')
      for _ in 0..<(indent - 1) {
        logger.write_char(' ')
      }
    }
    [sexp] => sexp.print_to(logger, indent~)
    [Atom(Field(name)) as field, value, Atom(Capture(_)) as capture, .. list] => {
      field.print_to(logger)
      logger.write_char(' ')
      value.print_to(logger, indent=indent + name.length() + 2)
      logger.write_char(' ')
      capture.print_to(logger)
      continue list
    }
    [Atom(Field(name)) as field, value] => {
      field.print_to(logger)
      logger.write_char(' ')
      value.print_to(logger, indent=indent + name.length() + 2)
    }
    [Atom(Field(name)) as field, value, .. list] => {
      field.print_to(logger)
      logger.write_char(' ')
      value.print_to(logger, indent=indent + name.length() + 2)
      logger.write_char('\n')
      for _ in 0..<indent {
        logger.write_char(' ')
      }
      continue list
    }
    [sexp, Atom(Capture(_)) as capture, .. list] => {
      sexp.print_to(logger, indent~)
      logger.write_char(' ')
      capture.print_to(logger)
      continue list
    }
    [sexp, .. list] => {
      sexp.print_to(logger, indent~)
      logger.write_char('\n')
      for _ in 0..<indent {
        logger.write_char(' ')
      }
      continue list
    }
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
    List(list, delimiter~, quantifier~) => {
      logger.write_char(delimiter.open())
      print_to(list, logger, indent=indent + 1)
      logger.write_char(delimiter.close())
      logger.write_object(quantifier)
    }
  }
}

///|
test "print" {
  let sexp : Sexp = Sexp::list([
    Atom(Symbol("a")),
    Atom(String("b")),
    Atom(Field("c")),
    Sexp::list([Atom(Symbol("d")), Atom(String("e"))]),
  ])
  let buffer = StringBuilder::new()
  sexp.print_to(buffer)
  inspect(
    buffer,
    content=(
      #|(a
      #| "b"
      #| c: (d
      #|     "e"))
    ),
  )
  let sexp = Sexp::list([
    Atom(Symbol("a")),
    Atom(String("b")),
    Atom(Field("c")),
    Sexp::list([Atom(Symbol("d")), Atom(String("e"))]),
    Atom(Capture("f")),
  ])
  buffer.reset()
  sexp.print_to(buffer)
  inspect(
    buffer,
    content=(
      #|(a
      #| "b"
      #| c: (d
      #|     "e") @f)
    ),
  )
}
