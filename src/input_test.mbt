///|
test "input creation and usage" {
  let parser = @tree_sitter.parser(@tree_sitter_json.language())
  let source =
    #|{"key": "value"}

  // Create an input using a custom function
  let input = @tree_sitter.Input::new(
    fn(offset, _) {
      // Return a slice of the source string as bytes
      let start = offset
      let mut end = offset + 5
      if start >= source.length() {
        return b""
      }
      if end > source.length() {
        end = source.length()
      }
      let view = source.view(start_offset=start, end_offset=end)
      let bytes = @encoding.encode(encoding=@encoding.UTF8, view)
      return bytes
    },
    @encoding.UTF8,
  )

  // Parse with our custom input
  let tree = parser.parse(input)

  // Verify the result
  let root = tree.root_node()
  inspect(root.child_count() > 0, content="true")
  let object_node = root.child(0).or_error(Failure("No object node found"))
  inspect(object_node.type_(), content="object")
}
