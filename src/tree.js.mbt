///|
type Tree

///|
priv trait Nullable {
  is_null(Self) -> Bool
  to_option(Self) -> Self? = _
}

///|
impl Nullable with to_option(self : Self) -> Self? {
  if self.is_null() {
    return None
  }
  Some(self)
}

///|
extern "js" fn ts_tree_null() -> Tree =
  #|() => {
  #|  return null;
  #|}

///|
extern "js" fn ts_tree_is_null(self : Tree) -> Bool =
  #|(tree) => {
  #|  return tree === null || tree === undefined;
  #|}

///|
impl Nullable for Tree with is_null(self : Tree) -> Bool {
  ts_tree_is_null(self)
}

///|
extern "js" fn ts_tree_copy(self : Tree) -> Tree =
  #|(tree) => {
  #|  return tree.copy();
  #|}

///|
/// Create a shallow copy of the syntax tree. This is very fast.
///
/// You need to copy a syntax tree in order to use it on more than one thread at
/// a time, as syntax trees are not thread safe.
pub fn Tree::copy(self : Tree) -> Tree {
  ts_tree_copy(self)
}

///|
extern "js" fn ts_tree_root_node(self : Tree) -> Node =
  #|(tree) => {
  #|  return tree.rootNode;
  #|}

///| Get the root node of the syntax tree.
pub fn Tree::root_node(self : Tree) -> Node {
  ts_tree_root_node(self)
}

///|
extern "js" fn ts_tree_root_node_with_offset(
  self : Tree,
  offset_bytes : UInt,
  offset_extent : Point
) -> Node =
  #|(tree, offsetBytes, offsetExtent) => {
  #|  return tree.rootNodeWithOffset(offset_bytes, offset_extent);
  #|}

///|
/// Get the root node of the syntax tree, but with its position
/// shifted forward by the given offset.
pub fn Tree::root_node_with_offset(
  self : Tree,
  offset_bytes : Int,
  offset_extent : Point
) -> Node {
  ts_tree_root_node_with_offset(self, int_to_uint(offset_bytes), offset_extent)
}

///|
extern "js" fn ts_tree_language(self : Tree) -> Language =
  #|(tree) => {
  #|  return tree.language;
  #|}

///|
/// Get the language that was used to parse the syntax tree.
pub fn Tree::language(self : Tree) -> Language {
  ts_tree_language(self)
}

///|
extern "js" fn ts_tree_included_ranges(self : Tree) -> Array[Range] =
  #|(tree) => {
  #|  return tree.getIncludedRanges();
  #|}

///|
/// Get the array of included ranges that was used to parse the syntax tree.
pub fn Tree::included_ranges(self : Tree) -> Array[Range] {
  ts_tree_included_ranges(self)
}

///|
extern "js" fn ts_tree_edit(self : Tree, edit : InputEdit) =
  #|(tree, edit) => {
  #|  return tree.edit(edit);
  #|}

///|
/// Edit the syntax tree to keep it in sync with source code that has been
/// edited.
///
/// You must describe the edit both in terms of byte offsets and in terms of
/// (row, column) coordinates.
pub fn Tree::edit(self : Tree, edit : InputEdit) -> Unit {
  ts_tree_edit(self, edit)
}

///|
extern "js" fn ts_tree_get_changed_ranges(
  self : Tree,
  other : Tree
) -> Array[Range] =
  #|(tree, other) => {
  #|  return tree.getChangedRanges(other);
  #|}

///|
/// Compare an old edited syntax tree to a new syntax tree representing the same
/// document, returning an array of ranges whose syntactic structure has changed.
///
/// For this to work correctly, the old syntax tree must have been edited such
/// that its ranges match up to the new tree. Generally, you'll want to call
/// this function right after calling one of the Parser::parse functions.
/// You need to pass the old tree that was passed to parse, as well as the new
/// tree that was returned from that function.
///
/// The returned ranges indicate areas where the hierarchical structure of syntax
/// nodes (from root to leaf) has changed between the old and new trees. Characters
/// outside these ranges have identical ancestor nodes in both trees.
///
/// Note that the returned ranges may be slightly larger than the exact changed areas,
/// but Tree-sitter attempts to make them as small as possible.
pub fn Tree::get_changed_ranges(self : Tree, other : Tree) -> Array[Range] {
  ts_tree_get_changed_ranges(self, other)
}

///|
pub fn Tree::query(
  self : Tree,
  query : @string.View
) -> QueryCursor raise QueryError {
  self.root_node().query(query)
}
