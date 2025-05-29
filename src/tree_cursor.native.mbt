///|
priv type TSTreeCursor

///|
struct TreeCursor {
  cursor : TSTreeCursor
  tree : TSTree
  text : @string.View
}

///|
#borrow(node)
extern "c" fn ts_tree_cursor_new(node : TSNode) -> TSTreeCursor = "moonbit_ts_tree_cursor_new"

///|
/// Create a new tree cursor starting from the given node.
///
/// A tree cursor allows you to walk a syntax tree more efficiently than is
/// possible using the `Node` functions. It is a mutable object that is always
/// on a certain syntax node, and can be moved imperatively to different nodes.
///
/// Note that the given node is considered the root of the cursor,
/// and the cursor cannot walk outside this node.
pub fn TreeCursor::new(node : Node) -> TreeCursor {
  let cursor = ts_tree_cursor_new(node.node)
  TreeCursor::{ cursor, tree: node.tree, text: node.text }
}

///|
#borrow(self, node)
extern "c" fn ts_tree_cursor_reset(self : TSTreeCursor, node : TSNode) = "moonbit_ts_tree_cursor_reset"

///|
/// Re-initialize a tree cursor to start at the original node that the cursor was
/// constructed with.
pub fn TreeCursor::reset(self : TreeCursor, node : Node) -> Unit {
  ts_tree_cursor_reset(self.cursor, node.node)
}

///|
#borrow(self, other)
extern "c" fn ts_tree_cursor_reset_to(
  self : TSTreeCursor,
  other : TSTreeCursor
) = "moonbit_ts_tree_cursor_reset_to"

///|
/// Re-initialize a tree cursor to the same position as another cursor.
///
/// Unlike TreeCursor::reset, this will not lose parent information and
/// allows reusing already created cursors.
pub fn TreeCursor::reset_to(self : TreeCursor, other : TreeCursor) -> Unit {
  ts_tree_cursor_reset_to(self.cursor, other.cursor)
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_current_node(self : TSTreeCursor) -> TSNode = "moonbit_ts_tree_cursor_current_node"

///|
/// Get the tree cursor's current node.
pub fn TreeCursor::current_node(self : TreeCursor) -> Node {
  return Node::{
    node: ts_tree_cursor_current_node(self.cursor),
    tree: self.tree,
    text: self.text,
  }
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_current_field_name(
  self : TSTreeCursor
) -> @native.ConstPtr[Byte] = "moonbit_ts_tree_cursor_current_field_name"

///|
/// Get the field name of the tree cursor's current node.
///
/// This returns `None` if the current node doesn't have a field.
/// See also `Node::child_by_field_name`.
pub fn TreeCursor::current_field_name(self : TreeCursor) -> String? {
  let name = ts_tree_cursor_current_field_name(self.cursor)
  decode_c_string(name)
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_current_field_id(self : TSTreeCursor) -> FieldId = "moonbit_ts_tree_cursor_current_field_id"

///|
/// Get the field id of the tree cursor's current node.
///
/// This returns zero if the current node doesn't have a field.
/// See also `Node::child_by_field_id`, `Language::field_id_for_name`.
pub fn TreeCursor::current_field_id(self : TreeCursor) -> FieldId {
  ts_tree_cursor_current_field_id(self.cursor)
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_goto_parent(self : TSTreeCursor) -> Bool = "moonbit_ts_tree_cursor_goto_parent"

///|
/// Move the cursor to the parent of its current node.
///
/// This returns `true` if the cursor successfully moved, and returns `false`
/// if there was no parent node (the cursor was already on the root node).
///
/// Note that the node the cursor was constructed with is considered the root
/// of the cursor, and the cursor cannot walk outside this node.
pub fn TreeCursor::goto_parent(self : TreeCursor) -> Bool {
  ts_tree_cursor_goto_parent(self.cursor)
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_goto_next_sibling(self : TSTreeCursor) -> Bool = "moonbit_ts_tree_cursor_goto_next_sibling"

///|
/// Move the cursor to the next sibling of its current node.
///
/// This returns `true` if the cursor successfully moved, and returns `false`
/// if there was no next sibling node.
///
/// Note that the node the cursor was constructed with is considered the root
/// of the cursor, and the cursor cannot walk outside this node.
pub fn TreeCursor::goto_next_sibling(self : TreeCursor) -> Bool {
  ts_tree_cursor_goto_next_sibling(self.cursor)
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_goto_previous_sibling(self : TSTreeCursor) -> Bool = "moonbit_ts_tree_cursor_goto_previous_sibling"

///|
/// Move the cursor to the previous sibling of its current node.
///
/// This returns `true` if the cursor successfully moved, and returns `false` if
/// there was no previous sibling node.
///
/// Note, that this function may be slower than `TreeCursor::goto_next_sibling`
/// due to how node positions are stored. In the worst case, this will need to
/// iterate through all the children up to the previous sibling node to recalculate
/// its position. Also note that the node the cursor was constructed with is
/// considered the root of the cursor, and the cursor cannot walk outside this node.
pub fn TreeCursor::goto_previous_sibling(self : TreeCursor) -> Bool {
  ts_tree_cursor_goto_previous_sibling(self.cursor)
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_goto_first_child(self : TSTreeCursor) -> Bool = "moonbit_ts_tree_cursor_goto_first_child"

///|
/// Move the cursor to the first child of its current node.
///
/// This returns `true` if the cursor successfully moved, and returns `false`
/// if there were no children.
pub fn TreeCursor::goto_first_child(self : TreeCursor) -> Bool {
  ts_tree_cursor_goto_first_child(self.cursor)
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_goto_last_child(self : TSTreeCursor) -> Bool = "moonbit_ts_tree_cursor_goto_last_child"

///|
/// Move the cursor to the last child of its current node.
///
/// This returns `true` if the cursor successfully moved, and returns `false` if
/// there were no children.
///
/// Note that this function may be slower than TreeCursor::goto_first_child
/// because it needs to iterate through all the children to compute the child's
/// position.
pub fn TreeCursor::goto_last_child(self : TreeCursor) -> Bool {
  ts_tree_cursor_goto_last_child(self.cursor)
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_goto_descendant(
  self : TSTreeCursor,
  goal_descendant_index : UInt
) -> Unit = "moonbit_ts_tree_cursor_goto_descendant"

///|
/// Move the cursor to the node that is the nth descendant of
/// the original node that the cursor was constructed with, where
/// zero represents the original node itself.
pub fn TreeCursor::goto_descendant(
  self : TreeCursor,
  goal_descendant_index : Int
) -> Unit {
  ts_tree_cursor_goto_descendant(
    self.cursor,
    int_to_uint(goal_descendant_index),
  )
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_current_descendant_index(
  self : TSTreeCursor
) -> UInt = "moonbit_ts_tree_cursor_current_descendant_index"

///|
/// Get the index of the cursor's current node out of all of the
/// descendants of the original node that the cursor was constructed with.
pub fn TreeCursor::current_descendant_index(self : TreeCursor) -> Int {
  uint_to_int(ts_tree_cursor_current_descendant_index(self.cursor))
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_current_depth(self : TSTreeCursor) -> UInt = "moonbit_ts_tree_cursor_current_depth"

///|
/// Get the depth of the cursor's current node relative to the original
/// node that the cursor was constructed with.
pub fn TreeCursor::current_depth(self : TreeCursor) -> Int {
  uint_to_int(ts_tree_cursor_current_depth(self.cursor))
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_goto_first_child_for_byte(
  self : TSTreeCursor,
  goal_byte : UInt
) -> Bool = "moonbit_ts_tree_cursor_goto_first_child_for_byte"

///|
/// Move the cursor to the first child of its current node that contains or starts after
/// the given byte offset.
///
/// This returns the index of the child node if one was found, and returns -1
/// if no such child was found.
pub fn TreeCursor::goto_first_child_for_byte(
  self : TreeCursor,
  goal_byte : Int
) -> Bool {
  ts_tree_cursor_goto_first_child_for_byte(self.cursor, int_to_uint(goal_byte))
}

///|
#borrow(self, goal_point)
extern "c" fn ts_tree_cursor_goto_first_child_for_point(
  self : TSTreeCursor,
  goal_point : Point
) -> Bool = "moonbit_ts_tree_cursor_goto_first_child_for_point"

///|
/// Move the cursor to the first child of its current node that contains or starts after
/// the given point.
///
/// This returns the index of the child node if one was found, and returns -1
/// if no such child was found.
pub fn TreeCursor::goto_first_child_for_point(
  self : TreeCursor,
  goal_point : Point
) -> Bool {
  ts_tree_cursor_goto_first_child_for_point(self.cursor, goal_point)
}

///|
#borrow(self)
extern "c" fn ts_tree_cursor_copy(self : TSTreeCursor) -> TSTreeCursor = "moonbit_ts_tree_cursor_copy"

///|
pub fn TreeCursor::copy(self : TreeCursor) -> TreeCursor {
  let cursor = ts_tree_cursor_copy(self.cursor)
  TreeCursor::{ cursor, tree: self.tree, text: self.text }
}
