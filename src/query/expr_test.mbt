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
    content=
      #|(structure
      #| (function_definition
      #|  (function_identifier
      #|   (lowercase_identifier))
      #|  (block_expression
      #|   (comment))))
    ,
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
