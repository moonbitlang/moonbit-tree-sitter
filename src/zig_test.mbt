///|
test "zig/parse" {
  let parser = @tree_sitter.parser(@tree_sitter_zig.language())
  let source =
    #|const std = @import("std");
    #|
    #|pub fn main() !void {
    #|    const stdout = std.io.getStdOut().writer();
    #|    try stdout.print("Hello, {s}!\n", .{"World"});
    #|}
  let tree = parser.parse_string(source)
  let root = tree.root_node()
  inspect(root.type_(), content="source_file")
  assert_false(root.has_error())
  assert_true(root.named_child_count() > 0)
}

///|
test "zig/query" {
  let parser = @tree_sitter.parser(@tree_sitter_zig.language())
  let source =
    #|fn add(a: i32, b: i32) i32 {
    #|    return a + b;
    #|}
    #|fn mul(a: i32, b: i32) i32 {
    #|    return a * b;
    #|}
  let tree = parser.parse_string(source)
  let query_cursor = tree.query("(function_declaration name: (identifier) @fn_name)")
  let funcs = []
  for match_ in query_cursor.matches() {
    for capture in match_.captures() {
      if capture.name() == "fn_name" {
        funcs.push(capture.node().text())
      }
    }
  }
  json_inspect(funcs, content=["add", "mul"])
}

///|
test "zig/language" {
  let language : @tree_sitter.Language = @tree_sitter_zig.language()
  inspect(language.name(), content=(
    #|Some("zig")
  ))
  assert_true(language.abi_version() > 0)
  assert_true(language.symbol_count() > 0)
}
