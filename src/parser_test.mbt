///|
test "parser creation and basic parsing" {
  // Create a parser for JSON
  let parser = @tree_sitter.parser(@tree_sitter_json.language())

  // Parse a simple JSON string
  let source =
    #|{"test": true, "numbers": [1, 2, 3]}
  let tree = parser.parse_string(source)

  // Check the root node
  let root = tree.root_node()
  inspect(root.type_(), content="document")

  // Make sure the tree structure is correct
  let object_node = root.child(0).or_error(Failure("No object node"))
  inspect(object_node.type_(), content="object")

  // Count named children
  let named_child_count = object_node.named_child_count()
  inspect(named_child_count, content="2")
}

///|
test "parser with included ranges" {
  let parser = @tree_sitter.parser(@tree_sitter_json.language())

  // Create a source that has JSON only in certain ranges
  let source =
    #|PREFIX {"value": 123} SUFFIX

  // Create a range that only includes the JSON part
  let start_point = @tree_sitter.Point::new(0, 7) // After PREFIX
  let end_point = @tree_sitter.Point::new(0, 21) // Before SUFFIX
  let range = @tree_sitter.Range::new(start_point, end_point, 7, 21)

  // Set included ranges on the parser
  parser.set_included_ranges([range]) |> ignore()

  // Parse the string
  let tree = parser.parse_string(source)

  // Check the included ranges on the tree
  let included_ranges = tree.included_ranges()
  inspect(included_ranges.length(), content="1")

  // Check the root node has the expected structure
  let root = tree.root_node()
  inspect(root.type_(), content="document")
  inspect(root.start_byte(), content="7") // Should start after PREFIX
  inspect(root.end_byte(), content="21") // Should end before SUFFIX
}
