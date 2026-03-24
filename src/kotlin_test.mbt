///|
test "kotlin/parse" {
  let parser = @tree_sitter.parser(@tree_sitter_kotlin.language())
  let source =
    #|fun main() {
    #|    val greeting = "Hello, World!"
    #|    println(greeting)
    #|}
    #|
    #|fun add(a: Int, b: Int): Int {
    #|    return a + b
    #|}
  let tree = parser.parse_string(source)
  let root = tree.root_node()
  inspect(root.type_(), content="source_file")
  assert_false(root.has_error())
  assert_true(root.named_child_count() > 0)
}

///|
test "kotlin/query" {
  let parser = @tree_sitter.parser(@tree_sitter_kotlin.language())
  let source =
    #|fun greet() {}
    #|fun calculate() {}
  let tree = parser.parse_string(source)
  let query_cursor = tree.query("(function_declaration (simple_identifier) @func_name)")
  let funcs = []
  for match_ in query_cursor.matches() {
    for capture in match_.captures() {
      if capture.name() == "func_name" {
        funcs.push(capture.node().text())
      }
    }
  }
  json_inspect(funcs, content=["greet", "calculate"])
}

///|
test "kotlin/language" {
  let language : @tree_sitter.Language = @tree_sitter_kotlin.language()
  inspect(language.name(), content=(
    #|Some("kotlin")
  ))
  assert_true(language.abi_version() > 0)
  assert_true(language.symbol_count() > 0)
}
