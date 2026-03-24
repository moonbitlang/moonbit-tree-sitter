///|
test "lua/parse" {
  let parser = @tree_sitter.parser(@tree_sitter_lua.language())
  let source =
    #|local function greet(name)
    #|  print("Hello, " .. name .. "!")
    #|end
    #|
    #|for i = 1, 10 do
    #|  greet("World")
    #|end
  let tree = parser.parse_string(source)
  let root = tree.root_node()
  inspect(root.type_(), content="chunk")
  assert_false(root.has_error())
  assert_true(root.named_child_count() > 0)
}

///|
test "lua/query" {
  let parser = @tree_sitter.parser(@tree_sitter_lua.language())
  let source =
    #|local function foo() end
    #|local function bar() end
  let tree = parser.parse_string(source)
  let query_cursor = tree.query("(function_declaration name: (identifier) @func_name)")
  let funcs = []
  for match_ in query_cursor.matches() {
    for capture in match_.captures() {
      if capture.name() == "func_name" {
        funcs.push(capture.node().text())
      }
    }
  }
  json_inspect(funcs, content=["foo", "bar"])
}

///|
test "lua/language" {
  let language : @tree_sitter.Language = @tree_sitter_lua.language()
  inspect(language.name(), content=(
    #|Some("lua")
  ))
  assert_true(language.abi_version() > 0)
  assert_true(language.symbol_count() > 0)
}
