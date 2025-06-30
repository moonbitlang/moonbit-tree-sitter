///|
struct Query {
  search : @tree_sitter.Query
  narrow : Map[String, @tree_sitter.Query]
}

///|
suberror ParseError {
  SyntaxError(@sexp.SexpError)
  QueryError(@tree_sitter.QueryError)
}

///|
pub fn Query::new(
  language : @tree_sitter.Language,
  query : @string.View
) -> Query raise ParseError {
  enum State {
    Search(StringBuilder)
    Narrow(String, StringBuilder)
  }
  let sexp_list = @sexp.parse(query) catch {
    error => raise ParseError::SyntaxError(error)
  }
  let search = StringBuilder::new()
  let narrow : Map[String, StringBuilder] = Map::new()
  let mut state = Search(StringBuilder::new())
  fn save() -> StringBuilder {
    match state {
      Search(buffer) => {
        if not(buffer.to_string().is_empty()) {
          search.write_string(buffer.to_string())
        }
        buffer.reset()
        buffer
      }
      Narrow(capture, buffer) =>
        match narrow.get(capture) {
          Some(narrow_buffer) => {
            narrow_buffer.write_string(buffer.to_string())
            buffer.reset()
            buffer
          }
          None => {
            narrow.set(capture, buffer)
            StringBuilder::new()
          }
        }
    }
  }

  fn skip_comment(sexp_list : ArrayView[@sexp.Sexp]) -> ArrayView[@sexp.Sexp] {
    loop sexp_list {
      [Atom(Comment(_)), .. sexp_list] => continue sexp_list
      [..] as sexp_list => return sexp_list
    }
  }

  fn parse(
    sexp_list : ArrayView[@sexp.Sexp],
    buffer : StringBuilder
  ) -> ArrayView[@sexp.Sexp] {
    match skip_comment(sexp_list) {
      [Atom(Field(_)) as field, .. sexp_list] => {
        field.output(buffer)
        match parse(sexp_list, buffer) {
          [Atom(Capture(_)) as capture, .. sexp_list] => {
            capture.output(buffer)
            return sexp_list
          }
          [.. sexp_list] => return sexp_list
        }
      }
      [sexp, .. sexp_list] => {
        sexp.output(buffer)
        match skip_comment(sexp_list) {
          [Atom(Capture(_)) as capture, .. sexp_list] => {
            capture.output(buffer)
            return sexp_list
          }
          [.. sexp_list] => return sexp_list
        }
      }
      [] => return []
    }
  }

  loop sexp_list[:] {
    [Atom(Comment(_)), .. sexp_list] => continue sexp_list
    [Atom(Narrow(capture)), .. sexp_list] => {
      let buffer = save()
      state = Narrow(capture, buffer)
      continue parse(sexp_list, buffer)
    }
    [_, ..] as sexp_list => {
      let buffer = save()
      state = Search(buffer)
      continue parse(sexp_list, buffer)
    }
    [] => break
  }
  ignore(save())
  let search = @tree_sitter.Query::new(language, search.to_string()) catch {
    error => raise ParseError::QueryError(error)
  }
  let narrow = {
    let map = Map::new()
    for capture, buffer in narrow {
      map[capture] = @tree_sitter.Query::new(language, buffer.to_string()) catch {
        error => raise ParseError::QueryError(error)
      }
    }
    map
  }
  { search, narrow }
}

///|
struct QueryCursor {
  query : Query
  cursor : @tree_sitter.QueryCursor
  captures : Map[String, Array[@tree_sitter.Node]]
}

///|
pub fn QueryCursor::new(query : Query) -> QueryCursor {
  let cursor = @tree_sitter.QueryCursor::new()
  let captures : Map[String, Array[@tree_sitter.Node]] = Map::new()
  { query, cursor, captures }
}

///|
pub fn QueryCursor::exec(self : QueryCursor, node : @tree_sitter.Node) -> Unit {
  let queue = @queue.new()
  self.captures.clear()
  self.cursor.exec(self.query.search, node)
  for capture in self.cursor.captures() {
    let name = capture.name()
    let node = capture.node()
    queue.push((name, node))
  }
  while queue.pop() is Some(capture) {
    let (name, node) = capture
    match self.query.narrow.get(name) {
      None =>
        match self.captures.get(name) {
          None => self.captures[name] = [node]
          Some(nodes) => nodes.push(node)
        }
      Some(query) => {
        self.cursor.exec(query, node)
        for capture in self.cursor.captures() {
          let name = capture.name()
          let node = capture.node()
          queue.push((name, node))
        }
      }
    }
  }
}

///|
pub fn QueryCursor::captures(
  self : QueryCursor
) -> Iter2[String, @tree_sitter.Node] {
  Iter2::new(fn(yield_) {
    captures~: for name, nodes in self.captures {
      for node in nodes {
        match yield_(name, node) {
          IterEnd => break captures~ IterEnd
          IterContinue => continue
        }
      }
    } else {
      IterContinue
    }
  })
}
