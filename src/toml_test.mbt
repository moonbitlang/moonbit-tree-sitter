///|
test "toml/parse" {
  let parser = @tree_sitter.parser(@tree_sitter_toml.language())
  let source =
    #|[package]
    #|name = "my-project"
    #|version = "0.1.0"
    #|
    #|[dependencies]
    #|serde = "1.0"
  let tree = parser.parse_string(source)
  let root = tree.root_node()
  inspect(root.type_(), content="document")
  assert_false(root.has_error())
  assert_true(root.named_child_count() > 0)
}

///|
test "toml/query" {
  let parser = @tree_sitter.parser(@tree_sitter_toml.language())
  let source =
    #|[package]
    #|name = "hello"
    #|version = "1.0"
  let tree = parser.parse_string(source)
  let query_cursor = tree.query("(pair (bare_key) @key)")
  let keys = []
  for match_ in query_cursor.matches() {
    for capture in match_.captures() {
      if capture.name() == "key" {
        keys.push(capture.node().text())
      }
    }
  }
  json_inspect(keys, content=["name", "version"])
}

///|
test "toml/language" {
  let language : @tree_sitter.Language = @tree_sitter_toml.language()
  inspect(language.name(), content=(
    #|Some("toml")
  ))
  assert_true(language.abi_version() > 0)
  assert_true(language.symbol_count() > 0)
}
