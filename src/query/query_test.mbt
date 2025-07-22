///|
test "Query::new" {
  let language = @tree_sitter_json.language()
  let parser = @tree_sitter.Parser::new()
  parser.set_language(language)
  let source =
    #|{
    #|  "name": "test",
    #|  "version": "1.0.0",
    #|  "description": "A test package"
    #|}
  let tree = parser.parse_string(source)
  inspect(
    tree.root_node(),
    content=(
      #|(document
      #| (object
      #|  (pair
      #|   key: (string
      #|         (string_content))
      #|   value: (string
      #|           (string_content)))
      #|  (pair
      #|   key: (string
      #|         (string_content))
      #|   value: (string
      #|           (string_content)))
      #|  (pair
      #|   key: (string
      #|         (string_content))
      #|   value: (string
      #|           (string_content)))))
    ),
  )
  let query =
    #|(object) @object
    #|
    #|@object:
    #| (pair
    #|  key: (string) @key
    #|  value: (string) @value)
  let query = @query.Query::new(language, query)
  let cursor = @query.QueryCursor::new(query)
  cursor.exec(tree.root_node())
  @json.inspect(cursor.captures().to_array(), content=[
    [
      "key",
      {
        "node": "(string (string_content))",
        "text": "\"name\"",
        "range": {
          "start": { "row": 1, "column": 2 },
          "end": { "row": 1, "column": 8 },
        },
      },
    ],
    [
      "key",
      {
        "node": "(string (string_content))",
        "text": "\"version\"",
        "range": {
          "start": { "row": 2, "column": 2 },
          "end": { "row": 2, "column": 11 },
        },
      },
    ],
    [
      "key",
      {
        "node": "(string (string_content))",
        "text": "\"description\"",
        "range": {
          "start": { "row": 3, "column": 2 },
          "end": { "row": 3, "column": 15 },
        },
      },
    ],
    [
      "value",
      {
        "node": "(string (string_content))",
        "text": "\"test\"",
        "range": {
          "start": { "row": 1, "column": 10 },
          "end": { "row": 1, "column": 16 },
        },
      },
    ],
    [
      "value",
      {
        "node": "(string (string_content))",
        "text": "\"1.0.0\"",
        "range": {
          "start": { "row": 2, "column": 13 },
          "end": { "row": 2, "column": 20 },
        },
      },
    ],
    [
      "value",
      {
        "node": "(string (string_content))",
        "text": "\"A test package\"",
        "range": {
          "start": { "row": 3, "column": 17 },
          "end": { "row": 3, "column": 33 },
        },
      },
    ],
  ])
}

///|
test "query/return" {
  let language = @tree_sitter_moonbit.language()
  let parser = @tree_sitter.Parser::new()
  parser.set_language(language)
  let source =
    #|fn main {
    #|  guard true is true else {
    #|    return 3
    #|  }
    #|  if true {
    #|    return 1
    #|  } else {
    #|    return 2
    #|  }
    #|}
  let tree = parser.parse_string(source)
  inspect(
    tree.root_node(),
    content=(
      #|(structure
      #| (function_definition
      #|  (function_identifier
      #|   (lowercase_identifier))
      #|  (block_expression
      #|   (guard_expression
      #|    (is_expression
      #|     (atomic_expression
      #|      (literal
      #|       (boolean_literal)))
      #|     (simple_pattern
      #|      (literal
      #|       (boolean_literal))))
      #|    (guard_else_expression
      #|     (block_expression
      #|      (return_expression
      #|       (atomic_expression
      #|        (literal
      #|         (integer_literal)))))))
      #|   (if_expression
      #|    (atomic_expression
      #|     (literal
      #|      (boolean_literal)))
      #|    (block_expression
      #|     (return_expression
      #|      (atomic_expression
      #|       (literal
      #|        (integer_literal)))))
      #|    (else_clause
      #|     (block_expression
      #|      (return_expression
      #|       (atomic_expression
      #|        (literal
      #|         (integer_literal))))))))))
    ),
  )
  let query =
    #|(function_definition
    #| (block_expression
    #|  (_) @tail .))
    #|
    #|@tail:
    #| (_
    #|  (if_expression
    #|   (block_expression
    #|    (_) @tail .)
    #|   (else_clause
    #|    (block_expression
    #|     (_) @tail .))))
    #|
    #|@tail:
    #|  (_ (return_expression) @return)
  let query = @query.Query::new(language, query)
  let cursor = @query.QueryCursor::new(query)
  cursor.exec(tree.root_node())
  @json.inspect(cursor.captures().to_array(), content=[
    [
      "return",
      {
        "node": "(return_expression (atomic_expression (literal (integer_literal))))",
        "text": "return 1",
        "range": {
          "start": { "row": 5, "column": 4 },
          "end": { "row": 5, "column": 12 },
        },
      },
    ],
    [
      "return",
      {
        "node": "(return_expression (atomic_expression (literal (integer_literal))))",
        "text": "return 2",
        "range": {
          "start": { "row": 7, "column": 4 },
          "end": { "row": 7, "column": 12 },
        },
      },
    ],
  ])
}
