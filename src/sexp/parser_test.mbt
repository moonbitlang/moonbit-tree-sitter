///|
test "parse" {
  @json.inspect(
    @sexp.parse(
      #|(structure
      #| (structure_item
      #|  (function_definition
      #|   (function_identifier
      #|    (lowercase_identifier)))))
      #|(ERROR (UNEXPECTED '`'))
      ,
    ),
    content=[
      {
        "open": "(",
        "close": ")",
        "list": [
          { "$tag": "Symbol", "0": "structure" },
          { "$tag": "Newline" },
          {
            "open": "(",
            "close": ")",
            "list": [
              { "$tag": "Symbol", "0": "structure_item" },
              { "$tag": "Newline" },
              {
                "open": "(",
                "close": ")",
                "list": [
                  { "$tag": "Symbol", "0": "function_definition" },
                  { "$tag": "Newline" },
                  {
                    "open": "(",
                    "close": ")",
                    "list": [
                      { "$tag": "Symbol", "0": "function_identifier" },
                      { "$tag": "Newline" },
                      {
                        "open": "(",
                        "close": ")",
                        "list": [
                          { "$tag": "Symbol", "0": "lowercase_identifier" },
                        ],
                        "quantifier": { "$tag": "One" },
                      },
                    ],
                    "quantifier": { "$tag": "One" },
                  },
                ],
                "quantifier": { "$tag": "One" },
              },
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
          { "$tag": "Symbol", "0": "ERROR" },
          {
            "open": "(",
            "close": ")",
            "list": [
              { "$tag": "Symbol", "0": "UNEXPECTED" },
              { "$tag": "String", "0": "`" },
            ],
            "quantifier": { "$tag": "One" },
          },
        ],
        "quantifier": { "$tag": "One" },
      },
    ],
  )
}

///|
test "[]" {
  @json.inspect(
    @sexp.parse(
      #|[
      #|  (expression)
      #|  (compound_expression)
      #|]
      ,
    ),
    content=[
      {
        "open": "[",
        "close": "]",
        "list": [
          { "$tag": "Newline" },
          {
            "open": "(",
            "close": ")",
            "list": [{ "$tag": "Symbol", "0": "expression" }],
            "quantifier": { "$tag": "One" },
          },
          { "$tag": "Newline" },
          {
            "open": "(",
            "close": ")",
            "list": [{ "$tag": "Symbol", "0": "compound_expression" }],
            "quantifier": { "$tag": "One" },
          },
          { "$tag": "Newline" },
        ],
        "quantifier": { "$tag": "One" },
      },
    ],
  )
}

///|
test "capture" {
  @json.inspect(
    @sexp.parse(
      #|(capture) @a
      ,
    ),
    content=[
      {
        "open": "(",
        "close": ")",
        "list": [{ "$tag": "Symbol", "0": "capture" }],
        "quantifier": { "$tag": "One" },
      },
      { "$tag": "Capture", "0": "a" },
    ],
  )
}

///|
test "void" {
  @json.inspect(
    @sexp.parse(
      #|
      ,
    ),
    content=[],
  )
}

///|
test "unit" {
  @json.inspect(
    @sexp.parse(
      #|()
      ,
    ),
    content=[
      { "open": "(", "close": ")", "list": [], "quantifier": { "$tag": "One" } },
    ],
  )
}

///|
test "pair" {
  @json.inspect(
    @sexp.parse(
      #|(key: value)
      ,
    ),
    content=[
      {
        "open": "(",
        "close": ")",
        "list": [{ "key": { "$tag": "Symbol", "0": "value" } }],
        "quantifier": { "$tag": "One" },
      },
    ],
  )
}

///|
test "pair with multiple values" {
  @json.inspect(
    @sexp.parse(
      #|(key: value1 value2)
      ,
    ),
    content=[
      {
        "open": "(",
        "close": ")",
        "list": [
          { "key": { "$tag": "Symbol", "0": "value1" } },
          { "$tag": "Symbol", "0": "value2" },
        ],
        "quantifier": { "$tag": "One" },
      },
    ],
  )
}

///|
test "comment" {
  @json.inspect(
    @sexp.parse(
      #|; comment
      ,
    ),
    content=[{ "$tag": "Comment", "0": " comment" }],
  )
}

///|
test "newline" {
  @json.inspect(
    @sexp.parse(
      #|
      #|
      #|(a
      #|
      #|  b)
      ,
    ),
    content=[
      { "$tag": "Newline" },
      { "$tag": "Newline" },
      {
        "open": "(",
        "close": ")",
        "list": [
          { "$tag": "Symbol", "0": "a" },
          { "$tag": "Newline" },
          { "$tag": "Newline" },
          { "$tag": "Symbol", "0": "b" },
        ],
        "quantifier": { "$tag": "One" },
      },
    ],
  )
}
