///|
test "bash/parse" {
  let parser = @tree_sitter.parser(@tree_sitter_bash.language())
  let source =
    #|#!/bin/bash
    #|
    #|greeting="Hello, World!"
    #|echo "$greeting"
    #|
    #|if [ -f "file.txt" ]; then
    #|  cat file.txt
    #|fi
  let tree = parser.parse_string(source)
  let root = tree.root_node()
  inspect(root.type_(), content="program")
  assert_false(root.has_error())
  assert_true(root.named_child_count() > 0)
}

///|
test "bash/query" {
  let parser = @tree_sitter.parser(@tree_sitter_bash.language())
  let source =
    #|name="world"
    #|count=42
  let tree = parser.parse_string(source)
  let query_cursor = tree.query("(variable_assignment name: (variable_name) @name) @assignment")
  let names = []
  for match_ in query_cursor.matches() {
    for capture in match_.captures() {
      if capture.name() == "name" {
        names.push(capture.node().text())
      }
    }
  }
  json_inspect(names, content=["name", "count"])
}

///|
test "bash/language" {
  let language : @tree_sitter.Language = @tree_sitter_bash.language()
  inspect(language.name(), content=(
    #|Some("bash")
  ))
  assert_true(language.abi_version() > 0)
  assert_true(language.symbol_count() > 0)
}
