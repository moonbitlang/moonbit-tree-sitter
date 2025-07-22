///|
test "node basic operations" {
  let parser = @tree_sitter.parser(@tree_sitter_json.language())
  let source =
    #|{"name": "test", "value": 123}
  let tree = parser.parse_string(source)
  let root = tree.root_node()

  // Test basic node properties
  inspect(root.type_(), content="document")
  inspect(root.is_named(), content="true")
  inspect(root.has_error(), content="false")

  // Test node navigation
  let object_node = root.child(0).or_error(Failure("No object node"))
  inspect(object_node.type_(), content="object")
  let name_pair = object_node.named_child(0).or_error(Failure("No name pair"))
  let value_pair = object_node.named_child(1).or_error(Failure("No value pair"))
  inspect(name_pair.type_(), content="pair")
  inspect(value_pair.type_(), content="pair")

  // Test node position information
  inspect(root.start_byte() == 0, content="true")
  let source_length = source.length()
  inspect(root.end_byte() == source_length, content="true")

  // Test node text extraction through string method
  let name_value_node = name_pair.child(1).or_error(Failure("No name value"))
  let name_value = name_value_node.string()
  inspect(
    name_value,
    content=(
      #|(":")
    ),
  )
}

///|
test "node advanced operations" {
  let parser = @tree_sitter.parser(@tree_sitter_json.language())
  let source =
    #|{"id": 1, "name": "test", "values": [true, false, null]}
  let tree = parser.parse_string(source)
  let root = tree.root_node()
  let object_node = root.child(0).or_error(Failure("No object node"))

  // Test named vs unnamed nodes
  inspect(root.is_named(), content="true")

  // Test child_by_field_name
  // Note: JSON language may not have field names, but we can test the API
  let maybe_field = object_node.child_by_field_name("key")
  inspect(maybe_field, content="None")

  // Test descendant_for_byte_range
  let name_value_node = object_node.descendant_for_byte_range(12, 18)
  inspect(
    name_value_node.map(Node::text(_)),
    content=(
      #|Some("\"name\": \"test\"")
    ),
  )

  // Test descendant_for_point_range
  let point_node = object_node.descendant_for_point_range(
    @tree_sitter.Point::new(0, 12),
    @tree_sitter.Point::new(0, 18),
  )
  inspect(
    point_node.map(Node::text(_)),
    content=(
      #|Some("\"name\": \"test\"")
    ),
  )

  // Test has_changes
  inspect(root.has_changes(), content="false")

  // Test edit - create a modified tree
  let edit = @tree_sitter.InputEdit::new(
    start_byte=12,
    old_end_byte=18,
    new_end_byte=21,
    start_point=@tree_sitter.Point::new(0, 12),
    old_end_point=@tree_sitter.Point::new(0, 18),
    new_end_point=@tree_sitter.Point::new(0, 21),
  )

  // Apply the edit
  let modified_tree = tree.copy()
  modified_tree.edit(edit)
  inspect(root.has_changes(), content="false")

  // Test named_child_count vs child_count
  let array_node = object_node
    .named_child(2)
    .or_error(Failure("No array node"))
    .child(1)
    .or_error(Failure("No array value node"))
  let named_count = array_node.named_child_count()
  let total_count = array_node.child_count()
  inspect(named_count < total_count, content="false")
}

///|
test "Node::eq" {
  let parser = @tree_sitter.parser(@tree_sitter_json.language())
  let source =
    #|{"key": "value"}
  let tree = parser.parse_string(source)
  let root_node = tree.root_node()
  let same_root_node = tree.root_node()
  assert_eq(root_node, same_root_node)
  assert_true(root_node.eq(same_root_node))
  let object_node = root_node.child(0).or_error(Failure("No object node"))
  assert_not_eq(root_node, object_node)
}

///|
test "Node::children" {
  let parser = @tree_sitter.parser(@tree_sitter_json.language())
  let source =
    #|[1, 2, 3, 4, 5]
  let tree = parser.parse_string(source)
  let root = tree.root_node()
  let array_node = root.child(0).or_error(Failure("No array node"))
  let children = []
  for child in array_node.children() {
    if child.is_named() {
      children.push(child.type_())
    }
  }
  @json.inspect(children, content=[
    "number", "number", "number", "number", "number",
  ])
}
