///|
test "language" {
  let language : @tree_sitter.Language = @tree_sitter_moonbit.language()
  inspect(
    language.name(),
    content=
      #|Some("moonbit")
    ,
  )
  assert_true(language.abi_version() > 0)
  assert_true(language.symbol_count() > 0)
}
