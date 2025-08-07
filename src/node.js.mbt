///|
type Node

///|
extern "js" fn ts_node_tree(node : Node) -> Tree =
  #|(node) => {
  #|  return node.tree;
  #|}

///|
extern "js" fn ts_node_type(node : Node) -> String =
  #|(node) => {
  #|  return node.type;
  #|}

///|
/// Get the node's type as a string.
pub fn Node::type_(self : Node) -> @string.View {
  ts_node_type(self)
}

///|
/// Get the node's type as a numerical id.
pub fn Node::symbol(self : Node) -> Symbol {
  self.language().symbol_for_name(self.type_()).unwrap()
}

///|
/// Get the node's language.
pub fn Node::language(self : Node) -> Language {
  ts_tree_language(ts_node_tree(self))
}

///|
extern "js" fn ts_node_grammar_type(node : Node) -> String =
  #|(node) => {
  #|  return node.grammarType;
  #|}

///|
/// Get the node's type as it appears in the grammar ignoring aliases as a string.
pub fn Node::grammar_type(self : Node) -> @string.View {
  ts_node_grammar_type(self)
}

///|
extern "js" fn ts_node_grammar_symbol(node : Node) -> Symbol =
  #|(node) => {
  #|  return node.grammarId;
  #|}

///|
/// Get the node's type as a numerical id as it appears in the grammar ignoring
/// aliases. This should be used in `Language::next_state` instead of
/// `Node::symbol`.
pub fn Node::grammar_symbol(self : Node) -> Symbol {
  return ts_node_grammar_symbol(self)
}

///|
extern "js" fn ts_node_start_byte(node : Node) -> Int =
  #|(node) => {
  #|  return node.startIndex;
  #|}

///|
/// Get the node's start byte.
pub fn Node::start_byte(self : Node) -> Int {
  return ts_node_start_byte(self)
}

///|
extern "js" fn ts_node_start_point(node : Node) -> Point =
  #|(node) => {
  #|  return node.startPosition;
  #|}

///|
/// Get the node's start position in terms of rows and columns.
pub fn Node::start_point(self : Node) -> Point {
  return ts_node_start_point(self)
}

///|
extern "js" fn ts_node_end_byte(node : Node) -> Int =
  #|(node) => {
  #|  return node.endIndex;
  #|}

///|
/// Get the node's end byte.
pub fn Node::end_byte(self : Node) -> Int {
  return ts_node_end_byte(self)
}

///|
extern "js" fn ts_node_string(node : Node) -> String =
  #|(node) => {
  #|  return node.toString();
  #|}

///|
/// Get an S-expression representing the node as a string.
pub fn Node::string(self : Node) -> @string.View {
  ts_node_string(self)
}

///|
pub impl Show for Node with output(self : Node, logger : &@builtin.Logger) -> Unit {
  try
    self.string() |> @sexp.parse() |> @sexp.print_to(logger)
  catch {
    _ => logger.write_string(self.string().to_string())
  }
}

///|
/// Get the node's end position in terms of rows and columns.
extern "js" fn ts_node_end_point(node : Node) -> Point =
  #|(node) => {
  #|  return node.endPosition;
  #|}

///|
pub fn Node::end_point(self : Node) -> Point {
  return ts_node_end_point(self)
}

///|
extern "js" fn ts_node_is_null(node : Node) -> Bool =
  #|(node) => {
  #|  return node == null || node == undefined;
  #|}

///|
/// Check if the node is null. Functions like `Node::child` and
/// `Node::next_sibling` will return a null node to indicate that no such node
/// was found.
pub fn Node::is_null(self : Node) -> Bool {
  return ts_node_is_null(self)
}

///|
extern "js" fn ts_node_is_named(node : Node) -> Bool =
  #|(node) => {
  #|  return node.isNamed;
  #|}

///|
/// Check if the node is *named*. Named nodes correspond to named rules in the
/// grammar, whereas *anonymous* nodes correspond to string literals in the
/// grammar.
pub fn Node::is_named(self : Node) -> Bool {
  return ts_node_is_named(self)
}

///|
extern "js" fn ts_node_is_missing(node : Node) -> Bool =
  #|(node) => {
  #|  return node.isMissing;
  #|}

///|
/// Check if the node is *missing*. Missing nodes are inserted by the parser in
/// order to recover from certain kinds of syntax errors.
pub fn Node::is_missing(self : Node) -> Bool {
  return ts_node_is_missing(self)
}

///|
extern "js" fn ts_node_is_extra(node : Node) -> Bool =
  #|(node) => {
  #|  return node.isExtra;
  #|}

///|
/// Check if the node is *extra*. Extra nodes represent things like comments,
/// which are not required the grammar, but can appear anywhere.
pub fn Node::is_extra(self : Node) -> Bool {
  return ts_node_is_extra(self)
}

///|
extern "js" fn ts_node_has_changes(node : Node) -> Bool =
  #|(node) => {
  #|  return node.hasChanges;
  #|}

///|
/// Check if a syntax node has been edited.
pub fn Node::has_changes(self : Node) -> Bool {
  return ts_node_has_changes(self)
}

///|
extern "js" fn ts_node_has_error(node : Node) -> Bool =
  #|(node) => {
  #|  return node.hasError;
  #|}

///|
/// Check if the node is a syntax error or contains any syntax errors.
pub fn Node::has_error(self : Node) -> Bool {
  return ts_node_has_error(self)
}

///|
extern "js" fn ts_node_is_error(node : Node) -> Bool =
  #|(node) => {
  #|  return node.isError;
  #|}

///|
/// Check if the node is a syntax error.
pub fn Node::is_error(self : Node) -> Bool {
  return ts_node_is_error(self)
}

///|
extern "js" fn ts_node_parse_state(node : Node) -> StateId =
  #|(node) => {
  #|  return node.parseState;
  #|}

///|
/// Get this node's parse state.
pub fn Node::parse_state(self : Node) -> StateId {
  return ts_node_parse_state(self)
}

///|
extern "js" fn ts_node_next_parse_state(node : Node) -> StateId =
  #|(node) => {
  #|  return node.nextParseState;
  #|}

///|
/// Get the parse state after this node.
pub fn Node::next_parse_state(self : Node) -> StateId {
  return ts_node_next_parse_state(self)
}

///|
extern "js" fn ts_node_parent(node : Node) -> Node =
  #|(node) => {
  #|  return node.parent;
  #|}

///|
/// Get the node's immediate parent.
/// Prefer `Node::child_with_descendant` for iterating over the node's ancestors.
pub fn Node::parent(self : Node) -> Node? {
  let parent = ts_node_parent(self)
  if ts_node_is_null(parent) {
    None
  } else {
    Some(parent)
  }
}

///|
extern "js" fn ts_node_child_with_descendant(
  node : Node,
  descendant : Node,
) -> Node =
  #|(node, descendant) => {
  #|  return node.childWithDescendant(descendant);
  #|}

///|
/// Get the node that contains `descendant`.
///
/// Note that this can return `descendant` itself.
pub fn Node::child_with_descendant(self : Node, descendant : Node) -> Node? {
  let child = ts_node_child_with_descendant(self, descendant)
  if ts_node_is_null(child) {
    None
  } else {
    Some(child)
  }
}

///|
extern "js" fn ts_node_child(node : Node, index : UInt) -> Node =
  #|(node, index) => {
  #|  return node.child(index);
  #|}

///|
fn int_to_uint(value : Int) -> UInt {
  guard value >= 0
  value.reinterpret_as_uint()
}

///|
fn uint_to_int(value : UInt) -> Int {
  guard value <= @int.max_value.reinterpret_as_uint()
  value.reinterpret_as_int()
}

///|
/// Get the node's child at the given index, where zero represents the first
/// child.
pub fn Node::child(self : Node, index : Int) -> Node? {
  let index = int_to_uint(index)
  let child = ts_node_child(self, index)
  if ts_node_is_null(child) {
    None
  } else {
    Some(child)
  }
}

///|
/// Get all children of the node.
pub fn Node::children(self : Node) -> Iter[Node] {
  Iter::new(fn(yield_) {
    for i in 0U..<ts_node_child_count(self) {
      let child = ts_node_child(self, i)
      match yield_(child) {
        IterEnd => return IterEnd
        IterContinue => continue
      }
    }
    IterContinue
  })
}

///|
extern "js" fn ts_node_field_name_for_child(
  node : Node,
  child_index : UInt,
) -> String =
  #|(node, tree, child_index) => {
  #|  return node.fieldNameForChild(child_index);
  #|}

///|
/// Get the field name for node's child at the given index, where zero represents
/// the first child. Returns `None`, if no field is found.
pub fn Node::field_name_for_child(
  self : Node,
  child_index : Int,
) -> @string.View? {
  let child_index = int_to_uint(child_index)
  let field_name = Nullable::to_option(
    ts_node_field_name_for_child(self, child_index),
  )
  if field_name is Some(field_name) {
    return Some(field_name)
  } else {
    return None
  }
}

///|
extern "js" fn ts_node_field_name_for_named_child(
  node : Node,
  child_index : UInt,
) -> String =
  #|(node, child_index) => {
  #|  return node.fieldNameForNamedChild(child_index);
  #|}

///|
/// Get the field name for node's named child at the given index, where zero
/// represents the first named child. Returns `None`, if no field is found.
pub fn Node::field_name_for_named_child(
  self : Node,
  child_index : Int,
) -> @string.View? {
  let child_index = int_to_uint(child_index)
  let field_name = Nullable::to_option(
    ts_node_field_name_for_named_child(self, child_index),
  )
  if field_name is Some(field_name) {
    return Some(field_name)
  } else {
    return None
  }
}

///|
extern "js" fn ts_node_child_count(node : Node) -> UInt =
  #|(node) => {
  #|  return node.childCount;
  #|}

///|
/// Get the node's number of children.
pub fn Node::child_count(self : Node) -> Int {
  uint_to_int(ts_node_child_count(self))
}

///|
extern "js" fn ts_node_named_child(node : Node, child_index : UInt) -> Node =
  #|(node, tree, child_index) => {
  #|  return node.namedChild(child_index);
  #|}

///|
/// Get the node's *named* child at the given index.
///
/// See also `Node::is_named`.
pub fn Node::named_child(self : Node, child_index : Int) -> Node? {
  let child_index = int_to_uint(child_index)
  let child = ts_node_named_child(self, child_index)
  if ts_node_is_null(child) {
    None
  } else {
    Some(child)
  }
}

///|
extern "js" fn ts_node_named_child_count(node : Node) -> UInt =
  #|(node) => {
  #|  return node.namedChildCount;
  #|}

///|
/// Get the node's number of *named* children.
///
/// See also `Node::is_named`.
pub fn Node::named_child_count(self : Node) -> Int {
  uint_to_int(ts_node_named_child_count(self))
}

///|
/// Get all named children of the node.
pub fn Node::named_children(self : Node) -> Iter[Node] {
  Iter::new(fn(yield_) {
    for i in 0U..<ts_node_named_child_count(self) {
      let child = ts_node_named_child(self, i)
      match yield_(child) {
        IterEnd => return IterEnd
        IterContinue => continue
      }
    }
    IterContinue
  })
}

///|
/// Get the node's child with the given field name.
extern "js" fn ts_node_child_by_field_name(node : Node, name : String) -> Node =
  #|(node, name) => {
  #|  return node.childForFieldName(name);
  #|}

///|
/// Get the node's child with the given field name.
pub fn Node::child_by_field_name(self : Node, name : @string.View) -> Node? {
  let child = ts_node_child_by_field_name(self, name.to_string())
  if ts_node_is_null(child) {
    None
  } else {
    Some(child)
  }
}

///|
extern "js" fn ts_node_child_by_field_id(node : Node, id : FieldId) -> Node =
  #|(node, id) => {
  #|  return node.childForFieldId(id);
  #|}

///|
/// Get the node's child with the given numerical field id.
///
/// You can convert a field name to an id using the
/// `Language::field_id_for_name` function.
pub fn Node::child_by_field_id(self : Node, id : FieldId) -> Node? {
  let child = ts_node_child_by_field_id(self, id)
  if ts_node_is_null(child) {
    None
  } else {
    Some(child)
  }
}

///|
extern "js" fn ts_node_next_sibling(node : Node) -> Node =
  #|(node) => {
  #|  return node.nextSibling;
  #|}

///|
/// Get the node's next sibling.
pub fn Node::next_sibling(self : Node) -> Node? {
  let next_sibling = ts_node_next_sibling(self)
  if ts_node_is_null(next_sibling) {
    None
  } else {
    Some(next_sibling)
  }
}

///|
extern "js" fn ts_node_prev_sibling(node : Node) -> Node =
  #|(node) => {
  #|  return node.prevSibling;
  #|}

///|
/// Get the node's previous sibling.
pub fn Node::prev_sibling(self : Node) -> Node? {
  let prev_sibling = ts_node_prev_sibling(self)
  if ts_node_is_null(prev_sibling) {
    None
  } else {
    Some(prev_sibling)
  }
}

///|
extern "js" fn ts_node_next_named_sibling(node : Node) -> Node =
  #|(node) => {
  #|  return node.nextNamedSibling;
  #|}

///|
/// Get the node's next *named* sibling.
pub fn Node::next_named_sibling(self : Node) -> Node? {
  let next_named_sibling = ts_node_next_named_sibling(self)
  if ts_node_is_null(next_named_sibling) {
    None
  } else {
    Some(next_named_sibling)
  }
}

///|
extern "js" fn ts_node_prev_named_sibling(node : Node) -> Node = "moonbit_ts_node_prev_named_sibling"

///|
/// Get the node's previous *named* sibling.
pub fn Node::prev_named_sibling(self : Node) -> Node? {
  let prev_named_sibling = ts_node_prev_named_sibling(self)
  if ts_node_is_null(prev_named_sibling) {
    None
  } else {
    Some(prev_named_sibling)
  }
}

///|
extern "js" fn ts_node_first_child_for_byte(node : Node, byte : UInt) -> Node =
  #|(node, byte) => {
  #|  return node.firstChildForIndex(byte);
  #|}

///|
/// Get the node's first child that contains or starts after the given byte offset.
pub fn Node::first_child_for_byte(self : Node, byte : Int) -> Node? {
  let byte = int_to_uint(byte)
  let child = ts_node_first_child_for_byte(self, byte)
  if ts_node_is_null(child) {
    None
  } else {
    Some(child)
  }
}

///|
extern "js" fn ts_node_first_named_child_for_byte(
  node : Node,
  byte : UInt,
) -> Node =
  #|(node, byte) => {
  #|  return node.firstNamedChildForIndex(byte);
  #|}

///|
/// Get the node's first named child that contains or starts after the given byte offset.
pub fn Node::first_named_child_for_byte(self : Node, byte : Int) -> Node? {
  let byte = int_to_uint(byte)
  let child = ts_node_first_named_child_for_byte(self, byte)
  if ts_node_is_null(child) {
    None
  } else {
    Some(child)
  }
}

///|
extern "js" fn ts_node_descendant_count(node : Node) -> Int =
  #|(node) => {
  #|  return node.descendantCount;
  #|}

///|
/// Get the node's number of descendants, including one for the node itself.
pub fn Node::descendant_count(self : Node) -> Int {
  return ts_node_descendant_count(self)
}

///|
extern "js" fn ts_node_descendant_for_byte_range(
  node : Node,
  start_byte : UInt,
  end_byte : UInt,
) -> Node =
  #|(node, start_byte, end_byte) => {
  #|  return node.descendantForIndex(start_byte, end_byte);
  #|}

///|
/// Get the smallest node within this node that spans the given range of bytes.
pub fn Node::descendant_for_byte_range(
  self : Node,
  start_byte : Int,
  end_byte : Int,
) -> Node? {
  let start_byte = int_to_uint(start_byte)
  let end_byte = int_to_uint(end_byte)
  let descendant = ts_node_descendant_for_byte_range(self, start_byte, end_byte)
  if ts_node_is_null(descendant) {
    None
  } else {
    Some(descendant)
  }
}

///|
extern "js" fn ts_node_descendant_for_point_range(
  node : Node,
  start_point : Point,
  end_point : Point,
) -> Node =
  #|(node, start_point, end_point) => {
  #|  return node.descendantForPosition(start_point, end_point);
  #|}

///|
/// Get the smallest node within this node that spans the given range of
/// (row, column) positions.
pub fn Node::descendant_for_point_range(
  self : Node,
  start_point : Point,
  end_point : Point,
) -> Node? {
  let descendant = ts_node_descendant_for_point_range(
    self, start_point, end_point,
  )
  if ts_node_is_null(descendant) {
    None
  } else {
    Some(descendant)
  }
}

///|
extern "js" fn ts_node_named_descendant_for_byte_range(
  node : Node,
  start_byte : UInt,
  end_byte : UInt,
) -> Node =
  #|(node, start_byte, end_byte) => {
  #|  return node.namedDescendantForIndex(start_byte, end_byte);
  #|}

///|
/// Get the smallest named node within this node that spans the given range of
/// bytes.
pub fn Node::named_descendant_for_byte_range(
  self : Node,
  start_byte : Int,
  end_byte : Int,
) -> Node? {
  let start_byte = int_to_uint(start_byte)
  let end_byte = int_to_uint(end_byte)
  let descendant = ts_node_named_descendant_for_byte_range(
    self, start_byte, end_byte,
  )
  if ts_node_is_null(descendant) {
    None
  } else {
    Some(descendant)
  }
}

///|
extern "js" fn ts_node_named_descendant_for_point_range(
  node : Node,
  start_point : Point,
  end_point : Point,
) -> Node =
  #|(node, start_point, end_point) => {
  #|  return node.namedDescendantForPosition(start_point, end_point);
  #|}

///|
/// Get the smallest named node within this node that spans the given
/// (row, column) positions.
pub fn Node::named_descendant_for_point_range(
  self : Node,
  start_point : Point,
  end_point : Point,
) -> Node? {
  let descendant = ts_node_named_descendant_for_point_range(
    self, start_point, end_point,
  )
  if ts_node_is_null(descendant) {
    None
  } else {
    Some(descendant)
  }
}

///|
extern "js" fn ts_node_edit(node : Node, edit : InputEdit) =
  #|(node, tree, edit) => {
  #|  return node.edit(edit);
  #|}

///|
/// Edit the node to keep it in-sync with source code that has been edited.
///
/// This function is only rarely needed. When you edit a syntax tree with the
/// `Tree::edit` function, all of the nodes that you retrieve from the tree
/// afterward will already reflect the edit. You only need to use `Node::edit`
/// when you have a `Node` instance that you want to keep and continue to use
/// after an edit.
pub fn Node::edit(self : Node, edit : InputEdit) -> Unit {
  ts_node_edit(self, edit)
}

///|
extern "js" fn ts_node_eq(node : Node, other : Node) -> Bool =
  #|(node, other) => {
  #|  return node.equals(other)
  #|}

///|
/// Check if two nodes are identical.
pub fn Node::eq(self : Node, other : Node) -> Bool {
  ts_node_eq(self, other)
}

///|
pub impl Eq for Node with op_equal(self, other) -> Bool {
  ts_node_eq(self, other)
}

///|
pub impl ToJson for Node with to_json(self : Node) -> Json {
  {
    "node": self.string().to_json(),
    "text": self.text().to_json(),
    "range": {
      "start": self.start_point().to_json(),
      "end": self.end_point().to_json(),
    },
  }
}

///|
extern "js" fn Node::id(self : Node) -> Int =
  #|(node) => {
  #|  return node.id;
  #|}

///|
pub impl Hash for Node with hash_combine(self, hasher) {
  let id = Node::id(self)
  hasher.combine(id)
}

///|
extern "js" fn ts_node_text(node : Node) -> String =
  #|(node) => {
  #|  return node.text;
  #|}

///|
pub fn Node::text(self : Node) -> @string.View {
  ts_node_text(self)
}

///|
pub fn Node::symbol_names(self : Node) -> Iter[String] {
  let language = self.language()
  let iterator = LookaheadIterator::new(language, self.parse_state())
  guard iterator is Some(iterator) else { return Iter::empty() }
  iterator.symbol_names()
}

///|
pub fn Node::next_symbol_names(self : Node) -> Iter[String] {
  let language = self.language()
  let iterator = LookaheadIterator::new(language, self.next_parse_state())
  guard iterator is Some(iterator) else { return Iter::empty() }
  iterator.symbol_names()
}

///|
pub fn Node::query(
  self : Node,
  source : @string.View,
) -> QueryCursor raise QueryError {
  let query = Query::new(self.language(), source)
  let query_cursor = QueryCursor::new()
  query_cursor.exec(query, self)
  return query_cursor
}
