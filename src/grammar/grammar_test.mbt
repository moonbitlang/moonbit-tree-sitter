///|
test {
  @async.start!(fn() {
    let grammar_json = @async.path!("grammar.json")
    let entries = @async.path!(["src", "languages"]).iter!().collect()
    for i = 0; i < entries.length(); i = i + 1 {
      let content = try (entries[i] / grammar_json).read_text!() catch {
        _ => continue
      }
      println("Testing grammar: \{entries[i]}")
      let json = @json.parse!(content)
      ignore((@json.from_json!(json) : @tree_sitter.Grammar))
    }
  })
}
