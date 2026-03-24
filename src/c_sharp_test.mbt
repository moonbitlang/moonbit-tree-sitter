///|
test "c_sharp/parse" {
  let parser = @tree_sitter.parser(@tree_sitter_c_sharp.language())
  let source =
    #|using System;
    #|
    #|namespace HelloWorld
    #|{
    #|    class Program
    #|    {
    #|        static void Main(string[] args)
    #|        {
    #|            Console.WriteLine("Hello, World!");
    #|        }
    #|    }
    #|}
  let tree = parser.parse_string(source)
  let root = tree.root_node()
  inspect(root.type_(), content="compilation_unit")
  assert_false(root.has_error())
  assert_true(root.named_child_count() > 0)
}

///|
test "c_sharp/query" {
  let parser = @tree_sitter.parser(@tree_sitter_c_sharp.language())
  let source =
    #|class Foo {
    #|    void Bar() {}
    #|    int Baz() { return 0; }
    #|}
  let tree = parser.parse_string(source)
  let query_cursor = tree.query("(method_declaration name: (identifier) @method_name)")
  let methods = []
  for match_ in query_cursor.matches() {
    for capture in match_.captures() {
      if capture.name() == "method_name" {
        methods.push(capture.node().text())
      }
    }
  }
  json_inspect(methods, content=["Bar", "Baz"])
}

///|
test "c_sharp/language" {
  let language : @tree_sitter.Language = @tree_sitter_c_sharp.language()
  inspect(language.name(), content=(
    #|Some("c_sharp")
  ))
  assert_true(language.abi_version() > 0)
  assert_true(language.symbol_count() > 0)
}
