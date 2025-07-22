///|
test "json" {
  let json = @tree_sitter_json.language()
  let parser = @tree_sitter.parser(json)
  let source =
    #|{
    #|  "name": "John Doe",
    #|  "age": 43
    #|}
  let tree = parser.parse_string(source)
  let root_node = tree.root_node()
  inspect(
    root_node,
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
      #|   value: (number))))
    ),
  )
  let root_node_first_child = root_node.child(0).or_error(Failure("None"))
  inspect(
    root_node_first_child,
    content=(
      #|(object
      #| (pair
      #|  key: (string
      #|        (string_content))
      #|  value: (string
      #|          (string_content)))
      #| (pair
      #|  key: (string
      #|        (string_content))
      #|  value: (number)))
    ),
  )
}

///|
test "moonbit" {
  let moonbit = @tree_sitter_moonbit.language()
  let parser = @tree_sitter.parser(moonbit)
  let source =
    #|fn main {
    #|  println("Hello, World!")
    #|}
    #|
    #|/// # Heading
    #|///
    #|/// Paragraph with *italic* and **bold** text.
    #|fn fib(a : Int) -> Int {
    #|  if a < 2 {
    #|    a
    #|  } else {
    #|    fib(a - 1) + fib(a - 2)
    #|  }
    #|}
  let tree = parser.parse_string(source)
  let comment_document = []
  let query_cursor = tree.query("(comment) @comment")
  for match_ in query_cursor.matches() {
    let comment_node = match_
      .captures()
      .filter(fn(x) { x.name() == "comment" })
      .peek()
      .or_error(Failure("No comment found"))
      .node()
    let start_byte = comment_node.start_byte()
    let end_byte = comment_node.end_byte()
    let comment = source.view(start_offset=start_byte, end_offset=end_byte)
    match comment {
      [.. "/// ", .. comment_content] =>
        comment_document.push(comment_content.to_string())
      [.. "///"] => comment_document.push("")
      _ => continue
    }
  }
  let comment_document = comment_document.join("\n")
  inspect(
    comment_document.to_string(),
    content=(
      #|# Heading
      #|
      #|Paragraph with *italic* and **bold** text.
    ),
  )
  parser.set_language(@tree_sitter_markdown.language())
  let markdown_tree = parser.parse_string(comment_document.to_string())
  let markdown_root_node = markdown_tree.root_node()
  inspect(
    markdown_root_node,
    content=(
      #|(document
      #| (section
      #|  (atx_heading
      #|   (atx_h1_marker)
      #|   heading_content: (inline))
      #|  (paragraph
      #|   (inline))))
    ),
  )
}

///|
test "markdown" {
  let moonbit = @tree_sitter_moonbit.language()
  let markdown = @tree_sitter_markdown.language()
  let parser = @tree_sitter.parser(markdown)
  let source =
    #|# Heading
    #|
    #|Paragraph with *italic* and **bold** text.
    #|
    #|```moonbit
    #|fn main {
    #|  println("Hello, World!")
    #|}
    #|```
  let tree = parser.parse_string(source)
  let root_node = tree.root_node()
  guard root_node.children().collect() is [document]
  guard document.children().collect() is [_, _, fenced_code_block]
  let moonbit_ranges = []
  for node in fenced_code_block.children() {
    if node.type_() == "code_fence_content" {
      let node_range = @tree_sitter.Range::new(
        node.start_point(),
        node.end_point(),
        node.start_byte(),
        node.end_byte(),
      )
      moonbit_ranges.push(node_range)
    } else {
      continue
    }
  }
  guard not(moonbit_ranges.is_empty())
  parser.set_language(moonbit)
  parser.set_included_ranges(moonbit_ranges) |> ignore()
}

///|
struct UTF32BE {}

///|
impl @tree_sitter.DecodeFunction for UTF32BE with decode(bytes : @bytes.View) -> @tree_sitter.DecodeResult? {
  match bytes {
    [a, b, c, d, .. _bytes] => {
      let bytes : Bytes = [a, b, c, d]
      match bytes[:].to_int_be().to_char() {
        Some(code_point) =>
          Some(@tree_sitter.DecodeResult::new(code_point~, bytes_read=4))
        None => None
      }
    }
    [.. _bytes] => None
  }
}

///|
test "custom-encoding" {
  let parser = @tree_sitter.parser(@tree_sitter_json.language())
  let source =
    #|{
    #|  "name": "John Doe",
    #|  "age": 43
    #|}
  let source_buffer = @buffer.new()
  loop source[:] {
    [char, .. source] => {
      let char = char.to_int()
      source_buffer.write_int_be(char)
      continue source
    }
    _ => break
  }
  let source_bytes = source_buffer.contents()
  let input = @tree_sitter.Input::new(
    fn(offset, _) {
      let start = offset
      let end = @cmp.minimum(offset + 4, source_bytes.length())
      return source_bytes[start:end]
    },
    UTF32BE::{  },
  )
  let tree = parser.parse(input)
  let root_node = tree.root_node()
  inspect(
    root_node,
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
      #|   value: (number))))
    ),
  )
}
