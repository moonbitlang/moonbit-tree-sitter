///|
test "typescript" {
  let typescript = @tree_sitter_typescript.language()
  let parser = @tree_sitter.parser(typescript)
  let source =
    #|function greet(name: string): string {
    #|  return `Hello, ${name}!`;
    #|}
  let tree = parser.parse_string(source)
  let root_node = tree.root_node()
  assert_true(root_node.child_count() > 0)
  assert_eq(root_node.type_(), "program")
}
