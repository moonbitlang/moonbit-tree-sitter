///|
test "range management" {
  // Test Range creation and getters
  let start_point = @tree_sitter.Point::new(1, 5)
  let end_point = @tree_sitter.Point::new(3, 10)
  let range = @tree_sitter.Range::new(start_point, end_point, 15, 45)

  // Verify the range properties
  inspect(range.start_point().row(), content="1")
  inspect(range.start_point().column(), content="5")
  inspect(range.end_point().row(), content="3")
  inspect(range.end_point().column(), content="10")
  inspect(range.start_byte(), content="15")
  inspect(range.end_byte(), content="45")
}

///|
test "range show implementation" {
  let start_point = @tree_sitter.Point::new(2, 8)
  let end_point = @tree_sitter.Point::new(4, 12)
  let range = @tree_sitter.Range::new(start_point, end_point, 20, 60)

  // Using inspect to test the Show implementation
  inspect(range, content="(2, 8) - (4, 12)")
}
