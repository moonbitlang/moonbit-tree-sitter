///|
test "sql/parse" {
  let parser = @tree_sitter.parser(@tree_sitter_sql.language())
  let source =
    #|SELECT id, name, email
    #|FROM users
    #|WHERE age > 18
    #|ORDER BY name;
  let tree = parser.parse_string(source)
  let root = tree.root_node()
  inspect(root.type_(), content="program")
  assert_false(root.has_error())
  assert_true(root.named_child_count() > 0)
}

///|
test "sql/query" {
  let parser = @tree_sitter.parser(@tree_sitter_sql.language())
  let source =
    #|SELECT name FROM users;
    #|SELECT id FROM orders;
  let tree = parser.parse_string(source)
  let query_cursor = tree.query("(relation (object_reference name: (identifier) @table_name))")
  let tables = []
  for match_ in query_cursor.matches() {
    for capture in match_.captures() {
      if capture.name() == "table_name" {
        tables.push(capture.node().text())
      }
    }
  }
  json_inspect(tables, content=["users", "orders"])
}

///|
test "sql/language" {
  let language : @tree_sitter.Language = @tree_sitter_sql.language()
  inspect(language.name(), content=(
    #|Some("sql")
  ))
  assert_true(language.abi_version() > 0)
  assert_true(language.symbol_count() > 0)
}
