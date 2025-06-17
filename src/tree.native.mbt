///|
priv type TSTree

///|
struct Tree {
  tree : TSTree
  text : @string.View
}

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
extern "c" fn ts_tree_null() -> TSTree = "moonbit_c_null"

///|
#borrow(tree)
extern "c" fn ts_tree_is_null(tree : TSTree) -> Bool = "moonbit_c_is_null"

///|
impl Nullable for TSTree with is_null(self : TSTree) -> Bool {
  ts_tree_is_null(self)
}

///|
#borrow(tree)
extern "c" fn ts_tree_copy(tree : TSTree) -> TSTree = "moonbit_ts_tree_copy"

///|
/// Create a shallow copy of the syntax tree. This is very fast.
///
/// You need to copy a syntax tree in order to use it on more than one thread at
/// a time, as syntax trees are not thread safe.
pub fn Tree::copy(self : Tree) -> Tree {
  { ..self, tree: ts_tree_copy(self.tree) }
}

///|
#borrow(tree)
extern "c" fn ts_tree_root_node(tree : TSTree) -> TSNode = "moonbit_ts_tree_root_node"

///| Get the root node of the syntax tree.
pub fn Tree::root_node(self : Tree) -> Node {
  Node::{ node: ts_tree_root_node(self.tree), tree: self.tree, text: self.text }
}

///|
#borrow(tree, offset_extent)
extern "c" fn ts_tree_root_node_with_offset(
  tree : TSTree,
  offset_bytes : UInt,
  offset_extent : Point
) -> TSNode = "moonbit_ts_tree_root_node_with_offset"

///|
/// Get the root node of the syntax tree, but with its position
/// shifted forward by the given offset.
pub fn Tree::root_node_with_offset(
  self : Tree,
  offset_bytes : Int,
  offset_extent : Point
) -> Node {
  let node = ts_tree_root_node_with_offset(
    self.tree,
    int_to_uint(offset_bytes),
    offset_extent,
  )
  { node, tree: self.tree, text: self.text }
}

///|
#borrow(tree)
extern "c" fn ts_tree_language(tree : TSTree) -> Language = "moonbit_ts_tree_language"

///|
/// Get the language that was used to parse the syntax tree.
pub fn Tree::language(self : Tree) -> Language {
  ts_tree_language(self.tree)
}

///|
#borrow(tree)
extern "c" fn ts_tree_included_ranges(tree : TSTree) -> FixedArray[UInt] = "moonbit_ts_tree_included_ranges"

///|
/// Get the array of included ranges that was used to parse the syntax tree.
pub fn Tree::included_ranges(self : Tree) -> Array[Range] {
  let flatten_ranges = ts_tree_included_ranges(self.tree)
  Array::makei(flatten_ranges.length() / 6, fn(i) {
    ts_range_new(
      ts_point_new(flatten_ranges[i * 6], flatten_ranges[i * 6 + 1]),
      ts_point_new(flatten_ranges[i * 6 + 2], flatten_ranges[i * 6 + 3]),
      flatten_ranges[i * 6 + 4],
      flatten_ranges[i * 6 + 5],
    )
  })
}

///|
#borrow(tree, edit)
extern "c" fn ts_tree_edit(tree : TSTree, edit : InputEdit) = "moonbit_ts_tree_edit"

///|
/// Edit the syntax tree to keep it in sync with source code that has been
/// edited.
///
/// You must describe the edit both in terms of byte offsets and in terms of
/// (row, column) coordinates.
pub fn Tree::edit(self : Tree, edit : InputEdit) -> Unit {
  ts_tree_edit(self.tree, edit)
}

///|
#borrow(tree, other)
extern "c" fn ts_tree_get_changed_ranges(
  tree : TSTree,
  other : TSTree
) -> FixedArray[UInt] = "moonbit_ts_tree_get_changed_ranges"

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
  let flatten_ranges = ts_tree_get_changed_ranges(self.tree, other.tree)
  Array::makei(flatten_ranges.length() / 6, fn(i) {
    ts_range_new(
      ts_point_new(flatten_ranges[i * 6], flatten_ranges[i * 6 + 1]),
      ts_point_new(flatten_ranges[i * 6 + 2], flatten_ranges[i * 6 + 3]),
      flatten_ranges[i * 6 + 4],
      flatten_ranges[i * 6 + 5],
    )
  })
}

///|
pub fn Tree::walk(self : Tree) -> TreeCursor {
  TreeCursor::new(self.root_node())
}

///|
pub fn Tree::query(
  self : Tree,
  source : @string.View
) -> QueryCursor raise QueryError {
  self.root_node().query(source)
}
