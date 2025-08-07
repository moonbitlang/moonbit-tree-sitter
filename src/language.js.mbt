///|
fn[T] async_suspend(f : ((T) -> Unit) -> Unit) -> T = "%async.suspend"

///|
type Language

///|
extern "js" fn ts_language_load_bytes(
  ts : TS,
  bytes : Bytes,
  resolve : (Language) -> Unit,
) -> Unit =
  #|(ts, bytes, resolve) => {
  #|  console.log("ts", ts);
  #|  return ts.Language.load(bytes).then(resolve);
  #|}

///|
pub async fn Language::load(bytes : Bytes) -> Language noraise {
  async_suspend(fn(resolve) { ts_language_load_bytes(ts, bytes, resolve) })
}

///|
extern "js" fn ts_language_is_null(language : Language) -> Bool =
  #|(language) => {
  #|  return language == null || language == undefined;
  #|}

///|
impl Nullable for Language with is_null(self : Language) -> Bool {
  ts_language_is_null(self)
}

///|
extern "js" fn ts_language_symbol_count(language : Language) -> UInt =
  #|(language) => {
  #|  return language.nodeTypeCount;
  #|}

///|
/// Get the number of distinct node types in the language.
pub fn Language::symbol_count(self : Language) -> Int {
  uint_to_int(ts_language_symbol_count(self))
}

///|
extern "js" fn ts_language_state_count(language : Language) -> UInt =
  #|(language) => {
  #|  return language.stateCount;
  #|}

///|
/// Get the number of valid states in this language.
pub fn Language::state_count(self : Language) -> Int {
  uint_to_int(ts_language_state_count(self))
}

///|
struct Symbol(UInt) derive(Eq)

///|
/// Get the numerical id for the given node type string.
extern "js" fn ts_language_symbol_for_name_(
  language : Language,
  name : Bytes,
) -> UInt16 =
  #|(language, name) => {
  #|  return language.idForNodeType(name, true) || language.idForNodeType(name, false);
  #|}

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
extern "js" fn ts_language_field_count(language : Language) -> Int =
  #|(language) => {
  #|  return language.fieldCount;
  #|}

///|
/// Get the number of distinct field names in the language.
pub fn Language::field_count(self : Language) -> Int {
  ts_language_field_count(self)
}

///|
extern "js" fn js_string_is_null(string : String) -> Bool =
  #|(string) => {
  #|  return string == null || string == undefined;
  #|}

///|
impl Nullable for String with is_null(self : String) -> Bool {
  js_string_is_null(self)
}

///|
extern "js" fn ts_language_field_name_for_id(
  language : Language,
  id : FieldId,
) -> String =
  #|(language, id) => {
  #|  return language.fieldNameForId(id);
  #|}

///|
/// Get the field name string for the given numerical id.
pub fn Language::field_name_for_id(
  self : Language,
  id : FieldId,
) -> @string.View? {
  if Nullable::to_option(ts_language_field_name_for_id(self, id))
    is Some(string) {
    Some(string)
  } else {
    None
  }
}

///|
extern "js" fn ts_language_field_id_for_name(
  language : Language,
  name : String,
) -> UInt =
  #|(language, name) => {
  #|  return language.fieldIdForName(name);
  #|}

///|
/// Get the numerical id for the given field name string.
pub fn Language::field_id_for_name(self : Language, name : @string.View) -> Int {
  ts_language_field_id_for_name(self, name.to_string()) |> uint_to_int()
}

///|
extern "js" fn ts_language_supertypes(language : Language) -> Array[Symbol] =
  #|(language) => {
  #|  return language.supertypes;
  #|}

///|
/// Get a list of all supertype symbols for the language.
pub fn Language::supertypes(self : Language) -> Array[Symbol] {
  return ts_language_supertypes(self)
}

///|
extern "js" fn ts_language_subtypes(language : Language) -> Array[Symbol] =
  #|(language) => {
  #|  return language.subtypes;
  #|}

///|
/// Get a list of all subtype symbol ids for a given supertype symbol.
///
/// See `Language::supertypes` for fetching all supertype symbols.
pub fn Language::subtypes(self : Language) -> Array[Symbol] {
  return ts_language_subtypes(self)
}

///|
extern "js" fn ts_language_symbol_name(
  language : Language,
  symbol : Symbol,
) -> String =
  #|(language, symbol) => {
  #|  return language.nodeTypeForId(symbol);
  #|}

///|
/// Get a node type string for the given numerical id.
pub fn Language::symbol_name(self : Language, symbol : Symbol) -> @string.View? {
  if Nullable::to_option(ts_language_symbol_name(self, symbol)) is Some(name) {
    Some(name)
  } else {
    None
  }
}

///|
/// Check whether the given node type id belongs to named nodes, anonymous nodes,
/// or a hidden nodes.
pub enum SymbolType {
  Regular
  Anonymous
  Supertype
  Auxiliary
}

///|
extern "js" fn ts_language_symbol_is_named(
  language : Language,
  symbol : Symbol,
) -> Bool =
  #|(language, symbol) => {
  #|  return language.nodeTypeIsNamed(symbol);
  #|}

///|
extern "js" fn ts_language_symbol_is_visible(
  language : Language,
  symbol : Symbol,
) -> Bool =
  #|(language, symbol) => {
  #|  return language.nodeTypeIsVisible(symbol);
  #|}

///|
/// Check whether the given node type id belongs to named nodes, anonymous nodes,
/// or a hidden nodes.
///
/// See also `Node::is_named`. Hidden nodes are never returned from the API.
pub fn Language::symbol_type(self : Language, symbol : Symbol) -> SymbolType {
  let named = ts_language_symbol_is_named(self, symbol)
  let visible = ts_language_symbol_is_visible(self, symbol)
  let supertypes = self.supertypes()
  if named && visible {
    return SymbolType::Regular
  } else if visible {
    return SymbolType::Anonymous
  } else if supertypes.contains(symbol) {
    return SymbolType::Supertype
  } else {
    return SymbolType::Auxiliary
  }
}

///|
extern "js" fn ts_language_version(language : Language) -> UInt =
  #|(language) => {
  #|  return language.version;
  #|}

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
extern "js" fn ts_language_abi_version(language : Language) -> UInt =
  #|(language) => {
  #|  return language.abiVersion;
  #|}

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
type LanguageMetadata

///|
pub extern "js" fn LanguageMetadata::major_version(
  self : LanguageMetadata,
) -> Byte =
  #|(metadata) => {
  #|  return metadata.major_version;
  #|}

///|
pub extern "js" fn LanguageMetadata::minor_version(
  self : LanguageMetadata,
) -> Byte =
  #|(metadata) => {
  #|  return metadata.minor_version;
  #|}

///|
pub extern "js" fn LanguageMetadata::patch_version(
  self : LanguageMetadata,
) -> Byte =
  #|(metadata) => {
  #|  return metadata.patch_version;
  #|}

///|
extern "js" fn ts_language_metadata(language : Language) -> LanguageMetadata =
  #|(language) => {
  #|  return language.metadata;
  #|}

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
extern "js" fn ts_language_next_state(
  language : Language,
  state : StateId,
  symbol : Symbol,
) -> StateId =
  #|(language, state, symbol) => {
  #|  return language.nextState(state, symbol);
  #|}

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
extern "js" fn ts_language_name(language : Language) -> String =
  #|(language) => {
  #|  return language.name;
  #|}

///|
/// Get the name of this language. This returns `None` in older parsers.
pub fn Language::name(self : Language) -> @string.View? {
  if Nullable::to_option(ts_language_name(self)) is Some(name) {
    Some(name)
  } else {
    None
  }
}
