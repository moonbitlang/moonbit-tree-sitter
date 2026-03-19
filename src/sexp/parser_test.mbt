///|
test "parse" {
  json_inspect(
    @sexp.parse(
      (
        #|(structure
        #| (structure_item
        #|  (function_definition
        #|   (function_identifier
        #|    (lowercase_identifier)))))
        #|(ERROR (UNEXPECTED '`'))
      ),
    ),
    content=[
      [
        "structure",
        [
          "structure_item",
          [
            "function_definition",
            ["function_identifier", ["lowercase_identifier"]],
          ],
        ],
      ],
      ["ERROR", ["UNEXPECTED", "\"`\""]],
    ],
  )
}

///|
test "[]" {
  json_inspect(
    @sexp.parse(
      (
        #|[
        #|  (expression)
        #|  (compound_expression)
        #|]
      ),
    ),
    content=[[["expression"], ["compound_expression"]]],
  )
}

///|
test "capture" {
  json_inspect(
    @sexp.parse(
      (
        #|(capture) @a
      ),
    ),
    content=[["capture"], "@a"],
  )
}

///|
test "void" {
  json_inspect(
    @sexp.parse(
      (
        #|
      ),
    ),
    content=[],
  )
}

///|
test "unit" {
  json_inspect(
    @sexp.parse(
      (
        #|()
      ),
    ),
    content=[[]],
  )
}

///|
test "pair" {
  json_inspect(
    @sexp.parse(
      (
        #|(key: value)
      ),
    ),
    content=[["key:", "value"]],
  )
}

///|
test "pair with multiple values" {
  json_inspect(
    @sexp.parse(
      (
        #|(key: value1 value2)
      ),
    ),
    content=[["key:", "value1", "value2"]],
  )
}

///|
test "comment" {
  json_inspect(
    @sexp.parse(
      (
        #|; comment
      ),
    ),
    content=["; comment"],
  )
}

///|
test "newline" {
  json_inspect(
    @sexp.parse(
      (
        #|
        #|
        #|(a
        #|
        #|  b)
      ),
    ),
    content=[["a", "b"]],
  )
}
