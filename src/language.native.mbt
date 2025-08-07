///|
pub(all) struct Language(@tree_sitter_language.Language)

///|
extern "c" fn ts_language_copy(language : Language) -> Language = "moonbit_ts_language_copy"

///|
/// Get another reference to the given language.
pub fn Language::copy(self : Language) -> Language {
  ts_language_copy(self)
}

///|
extern "c" fn ts_language_delete(language : Language) = "moonbit_ts_language_delete"

///|
/// Free any dynamically-allocated resources for this language, if
/// this is the last reference.
pub fn Language::delete(self : Language) -> Unit {
  ts_language_delete(self)
}

///|
extern "c" fn ts_language_symbol_count(language : Language) -> UInt = "moonbit_ts_language_symbol_count"

///|
/// Get the number of distinct node types in the language.
pub fn Language::symbol_count(self : Language) -> Int {
  uint_to_int(ts_language_symbol_count(self))
}

///|
extern "c" fn ts_language_state_count(language : Language) -> UInt = "moonbit_ts_language_state_count"

///|
/// Get the number of valid states in this language.
pub fn Language::state_count(self : Language) -> Int {
  uint_to_int(ts_language_state_count(self))
}

///|
struct Symbol(UInt)

///|
/// Get the numerical id for the given node type string.
#borrow(name)
extern "c" fn ts_language_symbol_for_name_(
  language : Language,
  name : Bytes,
) -> UInt16 = "moonbit_ts_language_symbol_for_name"

///|
/// Get the numerical id for the given node type string.
pub fn Language::symbol_for_name(
  self : Language,
  name : @string.View,
) -> Symbol? {
  let name_bytes = @encoding.encode(encoding=UTF8, name)
  let symbol = ts_language_symbol_for_name_(self, name_bytes)
  if symbol == 0 {
    return None
  } else {
    return Some(symbol.to_int().reinterpret_as_uint())
  }
}

///|
struct FieldId(UInt16)

///|
extern "c" fn ts_language_field_count(language : Language) -> Int = "moonbit_ts_language_field_count"

///|
/// Get the number of distinct field names in the language.
pub fn Language::field_count(self : Language) -> Int {
  ts_language_field_count(self)
}

///|
extern "c" fn ts_language_field_name_for_id(
  language : Language,
  id : FieldId,
) -> @native.ConstPtr[Byte] = "moonbit_ts_language_field_name_for_id"

///|
/// Get the field name string for the given numerical id.
pub fn Language::field_name_for_id(self : Language, id : FieldId) -> String? {
  let name_bytes = ts_language_field_name_for_id(self, id)
  decode_c_string(name_bytes)
}

///|
fn decode_c_string(c_string : @native.ConstPtr[Byte], length? : Int) -> String? {
  if c_string.is_null() {
    return None
  }
  let buffer = @buffer.new()
  match length {
    None => {
      let mut p = c_string
      while p.get() != 0 {
        buffer.write_byte(p.get())
        p = p.add(1)
      }
    }
    Some(length) =>
      for i = 0; i < length; i = i + 1 {
        buffer.write_byte(c_string.add(i.to_int64()).get())
      }
  }
  let name = buffer.contents()
  let name = @encoding.decode_lossy(encoding=UTF8, name)
  Some(name)
}

///|
#borrow(name)
extern "c" fn ts_language_field_id_for_name(
  language : Language,
  name : Bytes,
) -> UInt = "moonbit_ts_language_field_id_for_name"

///|
/// Get the numerical id for the given field name string.
pub fn Language::field_id_for_name(self : Language, name : @string.View) -> Int {
  let name_bytes = @encoding.encode(encoding=UTF8, name)
  ts_language_field_id_for_name(self, name_bytes) |> uint_to_int()
}

///|
extern "c" fn ts_language_supertypes(language : Language) -> Array[Symbol] = "moonbit_ts_language_supertypes"

///|
/// Get a list of all supertype symbols for the language.
pub fn Language::supertypes(self : Language) -> Array[Symbol] {
  return ts_language_supertypes(self)
}

///|
extern "c" fn ts_language_subtypes(language : Language) -> Array[Symbol] = "moonbit_ts_language_subtypes"

///|
/// Get a list of all subtype symbol ids for a given supertype symbol.
///
/// See `Language::supertypes` for fetching all supertype symbols.
pub fn Language::subtypes(self : Language) -> Array[Symbol] {
  return ts_language_subtypes(self)
}

///|
extern "c" fn ts_language_symbol_name(
  language : Language,
  symbol : Symbol,
) -> @native.ConstPtr[Byte] = "moonbit_ts_language_symbol_name"

///|
/// Get a node type string for the given numerical id.
pub fn Language::symbol_name(self : Language, symbol : Symbol) -> String? {
  let name_bytes = ts_language_symbol_name(self, symbol)
  return decode_c_string(name_bytes)
}

///|
/// Check whether the given node type id belongs to named nodes, anonymous nodes,
/// or a hidden nodes.
pub enum SymbolType {
  Regular = 0
  Anonymous = 1
  Supertype = 2
  Auxiliary = 3
}

///|
fn SymbolType::of_int(value : UInt) -> SymbolType {
  match value {
    0 => SymbolType::Regular
    1 => SymbolType::Anonymous
    2 => SymbolType::Supertype
    3 => SymbolType::Auxiliary
    value => abort("Invalid SymbolType: \{value}")
  }
}

///|
extern "c" fn ts_language_symbol_type(
  language : Language,
  symbol : Symbol,
) -> UInt = "moonbit_ts_language_symbol_type"

///|
/// Check whether the given node type id belongs to named nodes, anonymous nodes,
/// or a hidden nodes.
///
/// See also `Node::is_named`. Hidden nodes are never returned from the API.
pub fn Language::symbol_type(self : Language, symbol : Symbol) -> SymbolType {
  return SymbolType::of_int(ts_language_symbol_type(self, symbol))
}

///|
extern "c" fn ts_language_version(language : Language) -> UInt = "moonbit_ts_language_version"

///|
/// Get the ABI version number for this language. This version number is used
/// to ensure that languages were generated by a compatible version of
/// Tree-sitter.
///
/// See also `Parser::set_language`.
#deprecated("Use `Language::abi_version` instead")
pub fn Language::version(self : Language) -> Int {
  uint_to_int(ts_language_version(self))
}

///|
extern "c" fn ts_language_abi_version(language : Language) -> UInt = "moonbit_ts_language_abi_version"

///|
/// Get the ABI version number for this language. This version number is used
/// to ensure that languages were generated by a compatible version of
/// Tree-sitter.
///
/// See also `Parser::set_language`.
pub fn Language::abi_version(self : Language) -> Int {
  uint_to_int(ts_language_abi_version(self))
}

///|
/// The metadata associated with a language.
///
/// Currently, this metadata can be used to check the [Semantic Version](https://semver.org/)
/// of the language. This version information should be used to signal if a given parser might
/// be incompatible with existing queries when upgrading between major versions, or minor versions
/// if it's in zerover.
struct LanguageMetadata(Bytes)

///|
pub fn LanguageMetadata::major_version(self : LanguageMetadata) -> Byte {
  self.inner()[0]
}

///|
pub fn LanguageMetadata::minor_version(self : LanguageMetadata) -> Byte {
  self.inner()[1]
}

///|
pub fn LanguageMetadata::patch_version(self : LanguageMetadata) -> Byte {
  self.inner()[2]
}

///|
extern "c" fn ts_language_metadata(language : Language) -> LanguageMetadata = "moonbit_ts_language_metadata"

///|
/// Get the metadata for this language. This information is generated by the
/// CLI, and relies on the language author providing the correct metadata in
/// the language's `tree-sitter.json` file.
///
/// See also `LanguageMetadata`.
pub fn Language::metadata(self : Language) -> LanguageMetadata {
  return ts_language_metadata(self)
}

///|
struct StateId(UInt16)

///|
extern "c" fn ts_language_next_state(
  language : Language,
  state : StateId,
  symbol : Symbol,
) -> StateId = "moonbit_ts_language_next_state"

///|
/// Get the next parse state. Combine this with lookahead iterators to generate
/// completion suggestions or valid symbols in error nodes. Use
/// `Node::grammar_symbol` for valid symbols.
pub fn Language::next_state(
  self : Language,
  state : StateId,
  symbol : Symbol,
) -> StateId {
  return ts_language_next_state(self, state, symbol)
}

///|
extern "c" fn ts_language_name(language : Language) -> @native.ConstPtr[Byte] = "moonbit_ts_language_name"

///|
/// Get the name of this language. This returns `None` in older parsers.
pub fn Language::name(self : Language) -> String? {
  let name = ts_language_name(self.inner())
  return decode_c_string(name)
}
