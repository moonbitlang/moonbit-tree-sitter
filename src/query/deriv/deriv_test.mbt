///|
test {
  let moonbit = @tree_sitter_moonbit.language()
  let parser = @tree_sitter.Parser::new()
  parser.set_language(moonbit)
  let source =
    #|fn main {
    #|  // a
    #|}
  let tree = parser.parse_string(source)
  let root_node = tree.root_node()
  inspect(
    root_node,
    content=(
      #|(structure
      #| (function_definition
      #|  (function_identifier
      #|   (lowercase_identifier))
      #|  (block_expression
      #|   (comment))))
    ),
  )
  let expr = Expr::node(
    Node::and_(
      Node::type_("structure"),
      Node::descendant(
        Expr::seq(
          Expr::repeat(Expr::node(Node::truthy())),
          Expr::seq(
            Expr::capture(Expr::node(Node::type_("comment")), "comment"),
            Expr::repeat(Expr::node(Node::truthy())),
          ),
        ),
      ),
    ),
  )
  @json.inspect(expr.matches([root_node].iter()), content=[
    {
      "value": [
        {
          "node": "(structure (function_definition (function_identifier (lowercase_identifier)) (block_expression (comment))))",
          "text": "fn main {\n  // a\n}",
          "range": {
            "start": { "row": 0, "column": 0 },
            "end": { "row": 2, "column": 1 },
          },
        },
      ],
      "group": {
        "comment": [
          {
            "value": [
              {
                "node": "(comment)",
                "text": "// a",
                "range": {
                  "start": { "row": 1, "column": 2 },
                  "end": { "row": 1, "column": 6 },
                },
              },
            ],
            "group": {},
          },
        ],
      },
    },
  ])
  let expr = Expr::node(
    Node::and_(
      Node::type_("structure"),
      Node::descendant(
        Expr::capture(
          Expr::seq(
            Expr::repeat(Expr::node(Node::truthy())),
            Expr::seq(
              Expr::node(Node::type_("comment")),
              Expr::repeat(Expr::node(Node::truthy())),
            ),
          ),
          "comment",
        ),
      ),
    ),
  )
  @json.inspect(expr.matches([root_node].iter()), content=[
    {
      "value": [
        {
          "node": "(structure (function_definition (function_identifier (lowercase_identifier)) (block_expression (comment))))",
          "text": "fn main {\n  // a\n}",
          "range": {
            "start": { "row": 0, "column": 0 },
            "end": { "row": 2, "column": 1 },
          },
        },
      ],
      "group": {
        "comment": [
          {
            "value": [
              {
                "node": "(\"{\")",
                "text": "{",
                "range": {
                  "start": { "row": 0, "column": 8 },
                  "end": { "row": 0, "column": 9 },
                },
              },
              {
                "node": "(comment)",
                "text": "// a",
                "range": {
                  "start": { "row": 1, "column": 2 },
                  "end": { "row": 1, "column": 6 },
                },
              },
              {
                "node": "(\"}\")",
                "text": "}",
                "range": {
                  "start": { "row": 2, "column": 0 },
                  "end": { "row": 2, "column": 1 },
                },
              },
            ],
            "group": {},
          },
        ],
      },
    },
  ])
}

///|
test "bench" (b : @bench.T) {
  let moonbit = @tree_sitter_moonbit.language()
  let parser = @tree_sitter.Parser::new()
  parser.set_language(moonbit)
  let source =
    #|fn main {
    #|  // a
    #|  println("Hello, world!")
    #|  // b
    #|}
  let tree = parser.parse_string(source)
  let root_node = tree.root_node()
  inspect(
    root_node,
    content=(
      #|(structure
      #| (function_definition
      #|  (function_identifier
      #|   (lowercase_identifier))
      #|  (block_expression
      #|   (comment)
      #|   (apply_expression
      #|    (qualified_identifier
      #|     (lowercase_identifier))
      #|    (arguments
      #|     (argument
      #|      (atomic_expression
      #|       (literal
      #|        (string_literal
      #|         (string_fragment
      #|          (unescaped_string_fragment))))))))
      #|   (comment))))
    ),
  )
  let comment_matcher = Expr::node(Node::type_("comment"))
  let comment_capture = Expr::capture(comment_matcher, "comment")
  let comment_context = Expr::seq(
    Expr::repeat(Expr::node(Node::truthy())),
    Expr::seq(comment_capture, Expr::repeat(Expr::node(Node::truthy()))),
  )
  let block_matcher = Expr::node(
    Node::and_(Node::type_("block_expression"), Node::child(comment_context)),
  )
  let block_context = Expr::seq(
    Expr::repeat(Expr::node(Node::truthy())),
    block_matcher,
  )
  let function_matcher = Expr::node(
    Node::and_(Node::type_("function_definition"), Node::child(block_context)),
  )
  let function_context = Expr::seq(
    Expr::repeat(Expr::node(Node::truthy())),
    function_matcher,
  )
  let expr = Node::and_(Node::type_("structure"), Node::child(function_context))
  @json.inspect(expr.matches(root_node), content=[
    {
      "comment": [
        {
          "value": [
            {
              "node": "(comment)",
              "text": "// a",
              "range": {
                "start": { "row": 1, "column": 2 },
                "end": { "row": 1, "column": 6 },
              },
            },
          ],
          "group": {},
        },
        {
          "value": [
            {
              "node": "(comment)",
              "text": "// b",
              "range": {
                "start": { "row": 3, "column": 2 },
                "end": { "row": 3, "column": 6 },
              },
            },
          ],
          "group": {},
        },
      ],
    },
  ])
  let query = @tree_sitter.Query::new(
    moonbit,
    (
      #|(structure
      #| (function_definition
      #|  (block_expression
      #|   (comment) @comment)))
    ),
  )
  @json.inspect(query.matches(root_node).collect(), content=[
    {
      "id": 0,
      "pattern_index": 0,
      "captures": [{ "name": "comment", "node": "(comment)", "index": 0 }],
    },
    {
      "id": 1,
      "pattern_index": 0,
      "captures": [{ "name": "comment", "node": "(comment)", "index": 0 }],
    },
  ])
  // name  time (mean ± σ)         range (min … max)
  // deriv   35.15 µs ±   0.23 µs    34.69 µs …  35.50 µs  in 10 ×   2764 runs
  // query    2.16 µs ±   0.03 µs     2.12 µs …   2.22 µs  in 10 ×  46739 runs
  b.bench(name="deriv", fn() { ignore(expr.matches(root_node)) }, count=10)
  b.bench(
    name="query",
    fn() { ignore(query.matches(root_node).collect()) },
    count=10,
  )
}
