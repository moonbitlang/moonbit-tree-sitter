///|
test "query cursor basics" {
  let parser = @tree_sitter.parser(@tree_sitter_moonbit.language())
  let source =
    #|fn main {
    #|  let x = 10
    #|  let y = 20
    #|  let result = x + y
    #|  println(result)
    #|}
  let tree = parser.parse_string(source)

  // Create a query to find all variable declarations
  let query_source =
    #|(let_expression
    #| (pattern
    #|  (simple_pattern
    #|   (lowercase_identifier) @variable_name))
    #| (_) @variable_value)
  let query_cursor = tree.query(query_source)

  // Collect all variable declarations
  let variable_declarations = []
  for matched in query_cursor.matches() {
    let variable_name_node = matched
      .captures()
      .filter(fn(c) { c.name() == "variable_name" })
      .peek()
      .or_error(Failure("No variable name found"))
      .node()

    // We'll just use the name, not the value for this test
    let name = source
      .view(
        start_offset=variable_name_node.start_byte(),
        end_offset=variable_name_node.end_byte(),
      )
      .to_string()
    variable_declarations.push(name)
  }

  // We should find 3 variable declarations: x, y, and result
  inspect(variable_declarations.length(), content="3")
  inspect(variable_declarations[0], content="x")
  inspect(variable_declarations[1], content="y")
  inspect(variable_declarations[2], content="result")
}

///|
test "query cursor byte_range and point_range" {
  let parser = @tree_sitter.parser(@tree_sitter_moonbit.language())
  let source =
    #|fn func1() -> Int {
    #|  1
    #|}
    #|
    #|fn func2() -> Int {
    #|  2
    #|}
    #|
    #|fn func3() -> Int {
    #|  3
    #|}
  let tree = parser.parse_string(source)

  // Create a query to find all function definitions
  let query_source =
    #|(function_definition) @function

  // Test with a byte range that only includes the first two functions
  let cursor1 = tree.query(query_source)

  // Calculate end of first two functions (approximate)
  let end_byte = 40 // This should cover the first two functions
  cursor1.set_byte_range(0, end_byte)
  let matches1 = []
  for matched in cursor1.matches() {
    matches1.push(matched)
  }
  inspect(matches1.length(), content="2") // Should only find 2 functions

  // Test with point range
  let cursor2 = tree.query(query_source)
  cursor2.set_point_range(
    @tree_sitter.Point::new(0, 0),
    @tree_sitter.Point::new(1, 0), // First line only
  )
  let matches2 = []
  for matched in cursor2.matches() {
    matches2.push(matched)
  }
  inspect(matches2.length(), content="1") // Should only find 1 function
}

///|
test "query cursor with predicates" {
  let language = @tree_sitter_moonbit.language()
  let parser = @tree_sitter.parser(language)
  let source =
    #|fn main {
    #|  let x = 5
    #|  let y = 10
    #|  let z = 15
    #|  if x < y {
    #|    println("x is less than y")
    #|  }
    #|  if y < z {
    #|    println("y is less than z")
    #|  }
    #|}
  let tree = parser.parse_string(source)

  // Create a query to find if expressions with a specific condition
  let query_source =
    #|((if_expression
    #|  (binary_expression
    #|   (_) @left
    #|   "<"
    #|   (_) @right)) @if_block
    #| (#eq? @left "x"))
  let query_cursor = tree.query(query_source)
  let matches = []
  let predicates = []
  for matched in query_cursor.matches() {
    let captures = {}
    for capture in matched.captures() {
      captures[capture.name()] = capture.node().text()
    }
    matches.push(captures)
    predicates.push(matched.predicates())
  }
  @json.inspect(matches, content=[
    {
      "if_block": "if x < y {\n    println(\"x is less than y\")\n  }",
      "left": "x",
      "right": "y",
    },
    {
      "if_block": "if y < z {\n    println(\"y is less than z\")\n  }",
      "left": "y",
      "right": "z",
    },
  ])
  @json.inspect(predicates, content=[
    [["\"eq?\"", "@left", "\"x\""]],
    [["\"eq?\"", "@left", "\"x\""]],
  ])
}
