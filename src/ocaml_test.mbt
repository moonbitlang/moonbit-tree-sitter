///|
test "ocaml" {
  let ocaml = @tree_sitter_ocaml.language()
  let parser = @tree_sitter.parser(ocaml)
  let source =
    #|let rec fib n =
    #|  if n < 2 then n
    #|  else fib (n - 1) + fib (n - 2)
  let tree = parser.parse_string(source)
  let root_node = tree.root_node()
  assert_true(root_node.child_count() > 0)
  assert_eq(root_node.type_(), "compilation_unit")
}
