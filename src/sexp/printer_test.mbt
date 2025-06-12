///|
test "roundtrip" {
  let sexp =
    #|(a b c d: (f g))
    #|(h (j) (k (l)))
  let sexp = @sexp.parse(sexp)
  inspect(
    @sexp.print(sexp),
    content=
      #|(a b c d: (f g))
      #|(h (j) (k (l)))
    ,
  )
}

///|
test "brackets" {
  let sexp =
    #|[a b c d: [f g]]
    #|[h [j] [k [l]]]
  let sexp = @sexp.parse(sexp)
  inspect(
    @sexp.print(sexp),
    content=
      #|[a b c d: [f g]]
      #|[h [j] [k [l]]]
    ,
  )
}

///|
test "capture" {
  let sexp =
    #|(capture) @a
  let sexp = @sexp.parse(sexp)
  inspect(@sexp.print(sexp), content="(capture) @a")
}

///|
test "comment" {
  let sexp =
    #|; comment a
    #|a b c d: (f g) ; comment b
    #|; comment c
    #|(h (j) ; command d
    #|   (k (l)) ; comment e
    #|)
    #|
    #|(a b ; comment
    #|   c ; comment
    #|   d e f)
  let sexp = @sexp.parse(sexp)
  @json.inspect(sexp, content=[
    { "$tag": "Comment", "0": " comment a" },
    { "$tag": "Newline" },
    { "$tag": "Symbol", "0": "a" },
    { "$tag": "Symbol", "0": "b" },
    { "$tag": "Symbol", "0": "c" },
    {
      "d": {
        "open": "(",
        "close": ")",
        "list": [{ "$tag": "Symbol", "0": "f" }, { "$tag": "Symbol", "0": "g" }],
        "quantifier": { "$tag": "One" },
      },
    },
    { "$tag": "Comment", "0": " comment b" },
    { "$tag": "Newline" },
    { "$tag": "Comment", "0": " comment c" },
    { "$tag": "Newline" },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Symbol", "0": "h" },
        {
          "open": "(",
          "close": ")",
          "list": [{ "$tag": "Symbol", "0": "j" }],
          "quantifier": { "$tag": "One" },
        },
        { "$tag": "Comment", "0": " command d" },
        { "$tag": "Newline" },
        {
          "open": "(",
          "close": ")",
          "list": [
            { "$tag": "Symbol", "0": "k" },
            {
              "open": "(",
              "close": ")",
              "list": [{ "$tag": "Symbol", "0": "l" }],
              "quantifier": { "$tag": "One" },
            },
          ],
          "quantifier": { "$tag": "One" },
        },
        { "$tag": "Comment", "0": " comment e" },
        { "$tag": "Newline" },
      ],
      "quantifier": { "$tag": "One" },
    },
    { "$tag": "Newline" },
    { "$tag": "Newline" },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Symbol", "0": "a" },
        { "$tag": "Symbol", "0": "b" },
        { "$tag": "Comment", "0": " comment" },
        { "$tag": "Newline" },
        { "$tag": "Symbol", "0": "c" },
        { "$tag": "Comment", "0": " comment" },
        { "$tag": "Newline" },
        { "$tag": "Symbol", "0": "d" },
        { "$tag": "Symbol", "0": "e" },
        { "$tag": "Symbol", "0": "f" },
      ],
      "quantifier": { "$tag": "One" },
    },
  ])
  inspect(
    @sexp.print(sexp),
    content=
      #|; comment a
      #|a b c d: (f g) ; comment b
      #|; comment c
      #|(h (j) ; command d
      #| (k (l)) ; comment e
      #|)
      #|
      #|(a b ; comment
      #| c ; comment
      #| d e f)
    ,
  )
}

///|
test "newline" {
  let sexp =
    #|a
    #|
    #|(b
    #|
    #|  c)
  let sexp = @sexp.parse(sexp)
  @json.inspect(sexp, content=[
    { "$tag": "Symbol", "0": "a" },
    { "$tag": "Newline" },
    { "$tag": "Newline" },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Symbol", "0": "b" },
        { "$tag": "Newline" },
        { "$tag": "Newline" },
        { "$tag": "Symbol", "0": "c" },
      ],
      "quantifier": { "$tag": "One" },
    },
  ])
  inspect(
    @sexp.print(sexp),
    content=
      #|a
      #|
      #|(b
      #|
      #| c)
    ,
  )
}

///|
test "pretty" {
  let sexp =
    #|a ; comment after a
    #|
    #|  ; comment before (b
    #|(b ; comment after (b
    #|
    #|; comment before c
    #|  c) ; comment after c)
    #|
    #|(a
    #| (b
    #|  (c) ; comment after c
    #| )
    #|)
    #|
    #|(; first comment in list
    #|)(
    #| ; first comment in list with break
    #|)
    #|
    #|; last comment
  let sexp = @sexp.parse(sexp)
  @json.inspect(sexp, content=[
    { "$tag": "Symbol", "0": "a" },
    { "$tag": "Comment", "0": " comment after a" },
    { "$tag": "Newline" },
    { "$tag": "Newline" },
    { "$tag": "Comment", "0": " comment before (b" },
    { "$tag": "Newline" },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Symbol", "0": "b" },
        { "$tag": "Comment", "0": " comment after (b" },
        { "$tag": "Newline" },
        { "$tag": "Newline" },
        { "$tag": "Comment", "0": " comment before c" },
        { "$tag": "Newline" },
        { "$tag": "Symbol", "0": "c" },
      ],
      "quantifier": { "$tag": "One" },
    },
    { "$tag": "Comment", "0": " comment after c)" },
    { "$tag": "Newline" },
    { "$tag": "Newline" },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Symbol", "0": "a" },
        { "$tag": "Newline" },
        {
          "open": "(",
          "close": ")",
          "list": [
            { "$tag": "Symbol", "0": "b" },
            { "$tag": "Newline" },
            {
              "open": "(",
              "close": ")",
              "list": [{ "$tag": "Symbol", "0": "c" }],
              "quantifier": { "$tag": "One" },
            },
            { "$tag": "Comment", "0": " comment after c" },
            { "$tag": "Newline" },
          ],
          "quantifier": { "$tag": "One" },
        },
        { "$tag": "Newline" },
      ],
      "quantifier": { "$tag": "One" },
    },
    { "$tag": "Newline" },
    { "$tag": "Newline" },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Comment", "0": " first comment in list" },
        { "$tag": "Newline" },
      ],
      "quantifier": { "$tag": "One" },
    },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Newline" },
        { "$tag": "Comment", "0": " first comment in list with break" },
        { "$tag": "Newline" },
      ],
      "quantifier": { "$tag": "One" },
    },
    { "$tag": "Newline" },
    { "$tag": "Newline" },
    { "$tag": "Comment", "0": " last comment" },
  ])
  let result = []
  @sexp.pretty_to(sexp, result)
  @json.inspect(result, content=[
    { "$tag": "Symbol", "0": "a" },
    { "$tag": "Comment", "0": " comment after a" },
    { "$tag": "Newline" },
    { "$tag": "Comment", "0": " comment before (b" },
    { "$tag": "Newline" },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Symbol", "0": "b" },
        { "$tag": "Comment", "0": " comment after (b" },
        { "$tag": "Newline" },
        { "$tag": "Comment", "0": " comment before c" },
        { "$tag": "Newline" },
        { "$tag": "Symbol", "0": "c" },
      ],
      "quantifier": { "$tag": "One" },
    },
    { "$tag": "Comment", "0": " comment after c)" },
    { "$tag": "Newline" },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Symbol", "0": "a" },
        { "$tag": "Newline" },
        {
          "open": "(",
          "close": ")",
          "list": [
            { "$tag": "Symbol", "0": "b" },
            { "$tag": "Newline" },
            {
              "open": "(",
              "close": ")",
              "list": [{ "$tag": "Symbol", "0": "c" }],
              "quantifier": { "$tag": "One" },
            },
            { "$tag": "Comment", "0": " comment after c" },
            { "$tag": "Newline" },
          ],
          "quantifier": { "$tag": "One" },
        },
      ],
      "quantifier": { "$tag": "One" },
    },
    { "$tag": "Newline" },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Comment", "0": " first comment in list" },
        { "$tag": "Newline" },
      ],
      "quantifier": { "$tag": "One" },
    },
    { "$tag": "Newline" },
    {
      "open": "(",
      "close": ")",
      "list": [
        { "$tag": "Comment", "0": " first comment in list with break" },
        { "$tag": "Newline" },
      ],
      "quantifier": { "$tag": "One" },
    },
    { "$tag": "Newline" },
    { "$tag": "Comment", "0": " last comment" },
    { "$tag": "Newline" },
  ])
  inspect(
    @sexp.print(result),
    content=
      #|a ; comment after a
      #|; comment before (b
      #|(b ; comment after (b
      #| ; comment before c
      #| c) ; comment after c)
      #|(a
      #| (b
      #|  (c) ; comment after c
      #| ))
      #|(; first comment in list
      #|)
      #|(; first comment in list with break
      #|)
      #|; last comment
      #|
    ,
  )
}

///|
test "prettify" {
  let source =
    #|;; exp
    #|(structure (structure_item (function_definition ("fn") (function_identifier (lowercase_identifier)) (block_expression ("{") (statement_expression (expression (pipeline_expression (compound_expression (binary_expression ([
    #|  (compound_expression)
    #|  (expression)
    #|]) @a ("==") ([
    #|  (compound_expression)
    #|  (expression)
    #|]) @b))))) ("}")))))
  inspect(
    @sexp.prettify(source),
    content=
      #|;; exp
      #|(structure
      #| (structure_item
      #|  (function_definition
      #|   ("fn")
      #|   (function_identifier
      #|    (lowercase_identifier))
      #|   (block_expression
      #|    ("{")
      #|    (statement_expression
      #|     (expression
      #|      (pipeline_expression
      #|       (compound_expression
      #|        (binary_expression
      #|         ([(compound_expression)
      #|           (expression)]) @a
      #|         ("==")
      #|         ([(compound_expression)
      #|           (expression)]) @b)))))
      #|    ("}")))))
    ,
  )
}
