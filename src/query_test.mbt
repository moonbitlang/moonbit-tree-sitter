///|
test "query with predicates" {
  // Create a simple query with a single pattern
  let language = @tree_sitter_moonbit.language()

  // Create a query with a pattern that has multiple captures
  let query_source =
    #|((function_definition
    #|  (function_identifier
    #|   (lowercase_identifier) @func_name)
    #|  (parameters) @params)
    #| (#eq? @func_name "f"))
  let query = @tree_sitter.Query::new(language, query_source)

  // Get the pattern count
  inspect(query.pattern_count(), content="1")

  // Test the quantifier for a capture
  let quantifier = query.capture_quantifier_for_id(0, 0)
  inspect(quantifier, content="One")

  // Test predicates for a pattern
  let predicates = query.predicates_for_pattern(0)
  // This pattern doesn't have predicates
  inspect(predicates.length(), content="1")

  // Test string_value_for_id for a string in the query
  inspect(
    query.string_value_for_id(0),
    content=
      #|Some("eq?")
    ,
  )
}

///|
test "query" {
  let parser = @tree_sitter.parser(@tree_sitter_moonbit.language())
  let source =
    #|fn main {
    #|  if 1 == 1 {
    #|    println("Hello, world!")
    #|  }
    #|  for i = 0; i < 10; i = i + 1 {
    #|    println("Hello, world!")
    #|  }
    #|}
  let source_tree = parser.parse_string(source)
  let query =
    #|(for_expression) @forExpression
  let query_cursor = source_tree.query(query)
  let captures = {}
  for matched in query_cursor.matches() {
    for capture in matched.captures() {
      captures[capture.name()] = capture.node().text()
    }
  }
  @json.inspect(captures, content={
    "forExpression": "for i = 0; i < 10; i = i + 1 {\n    println(\"Hello, world!\")\n  }",
  })
}
