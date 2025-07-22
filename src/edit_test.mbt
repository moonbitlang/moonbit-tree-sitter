///|
struct Edit {
  name : @string.View
  search : @string.View
  replace : @string.View
} derive(Show, ToJson)

///|
fn parse_rules(source : Bytes) -> Array[Edit] raise {
  let yaml = @tree_sitter_yaml.language()
  let parser = @tree_sitter.parser(yaml)
  let source_tree = parser.parse_bytes(source, encoding=@encoding.UTF8)
  let source_root = source_tree.root_node()
  let query_source =
    #|(block_mapping_pair
    #| key: (_) @name
    #| value:
    #| (block_node
    #|  (block_mapping
    #|   (block_mapping_pair
    #|    key: (_) @_search
    #|    value: (_) @search)
    #|   (#eq? @_search "search")
    #|   (block_mapping_pair
    #|    key: (_) @_replace
    #|    value: (_) @replace)
    #|   (#eq? @_replace "replace"))))
  let query_cursor = source_root.query(query_source)
  let edits : Array[Edit] = []
  while query_cursor.next_match() is Some(matched) {
    let captures_nodes = {}
    let captures_texts = {}
    for capture in matched.captures() {
      let node = capture.node()
      let bytes = source[node.start_byte():node.end_byte()]
      let text = @encoding.decode(encoding=UTF8, [..bytes])
      captures_nodes[capture.name().to_string()] = node
      captures_texts[capture.name().to_string()] = text
    }
    guard captures_texts.get("name") is Some(name) else {
      fail("Error: missing name")
    }
    guard captures_texts.get("search") is Some(search) else {
      fail("Error: missing search")
    }
    let search = match search.trim_space() {
      ['|', '\n', .. search] => search
      search => search
    }
    guard captures_texts.get("replace") is Some(replace) else {
      fail("Error: missing replace")
    }
    let replace = match replace.trim_space() {
      ['|', '\n', .. replace] => replace
      replace => replace
    }
    edits.push(Edit::{
      name,
      search: search.trim_space().to_string(),
      replace: replace.trim_space().to_string(),
    })
  }
  return edits
}

///|
test "parse_rules" {
  let rules =
    #|suggested-for-in:
    #|  search: |
    #|    ((for_expression
    #|      (for_binder
    #|       (lowercase_identifier) @binderDefinition
    #|        (expression
    #|         (pipeline_expression
    #|          (compound_expression
    #|           (simple_expression
    #|            (atomic_expression
    #|             (literal
    #|              (integer_literal) @rangeLower)))))))
    #|        .
    #|        (semicolon)
    #|        (compound_expression
    #|         (binary_expression
    #|         (_) @binderConditional
    #|         "<"
    #|         (_) @rangeUpper))
    #|        (semicolon)
    #|        (for_binder
    #|         (lowercase_identifier) @binderAssignment
    #|         (expression
    #|         (pipeline_expression
    #|          (compound_expression
    #|           (binary_expression
    #|              (_) @binderUpdate
    #|              "+"
    #|              (_) @rangeStep)))))
    #|        (block_expression) @forBody
    #|        (else_clause)? @forBody)
    #|     (#eq? @binderDefinition @binderConditional)
    #|     (#eq? @binderDefinition @binderAssignment)
    #|     (#eq? @binderDefinition @binderUpdate)
    #|     (#eq? @rangeStep "1"))
    #|  replace: |
    #|    for $binderDefinition in $rangeLower..<($rangeUpper) $forBody
    #|
  let rules = parse_rules(@encoding.encode(encoding=UTF8, rules))
  @json.inspect(rules, content=[
    {
      "name": "suggested-for-in",
      "search": (
        #|((for_expression
        #|      (for_binder
        #|       (lowercase_identifier) @binderDefinition
        #|        (expression
        #|         (pipeline_expression
        #|          (compound_expression
        #|           (simple_expression
        #|            (atomic_expression
        #|             (literal
        #|              (integer_literal) @rangeLower)))))))
        #|        .
        #|        (semicolon)
        #|        (compound_expression
        #|         (binary_expression
        #|         (_) @binderConditional
        #|         "<"
        #|         (_) @rangeUpper))
        #|        (semicolon)
        #|        (for_binder
        #|         (lowercase_identifier) @binderAssignment
        #|         (expression
        #|         (pipeline_expression
        #|          (compound_expression
        #|           (binary_expression
        #|              (_) @binderUpdate
        #|              "+"
        #|              (_) @rangeStep)))))
        #|        (block_expression) @forBody
        #|        (else_clause)? @forBody)
        #|     (#eq? @binderDefinition @binderConditional)
        #|     (#eq? @binderDefinition @binderAssignment)
        #|     (#eq? @binderDefinition @binderUpdate)
        #|     (#eq? @rangeStep "1"))
      ),
      "replace": "for $binderDefinition in $rangeLower..<($rangeUpper) $forBody",
    },
  ])
}
