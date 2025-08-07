///|
priv struct TSNode(Bytes)

///|
struct Node {
  node : TSNode
  tree : TSTree
  text : @string.View
}

///|
#borrow(node, tree)
extern "c" fn ts_node_type(
  node : TSNode,
  tree : TSTree,
) -> @native.ConstPtr[Byte] = "moonbit_ts_node_type"

///|
/// Get the node's type as a string.
pub fn Node::type_(self : Node) -> String {
  return decode_c_string(ts_node_type(self.node, self.tree)).unwrap()
}

///|
#borrow(node, tree)
extern "c" fn ts_node_symbol(node : TSNode, tree : TSTree) -> Symbol = "moonbit_ts_node_symbol"

///|
/// Get the node's type as a numerical id.
pub fn Node::symbol(self : Node) -> Symbol {
  return ts_node_symbol(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_language(node : TSNode, tree : TSTree) -> Language = "moonbit_ts_node_language"

///|
/// Get the node's language.
pub fn Node::language(self : Node) -> Language {
  return ts_node_language(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_grammar_type(
  node : TSNode,
  tree : TSTree,
) -> @native.ConstPtr[Byte] = "moonbit_ts_node_grammar_type"

///|
/// Get the node's type as it appears in the grammar ignoring aliases as a string.
pub fn Node::grammar_type(self : Node) -> String {
  return decode_c_string(ts_node_grammar_type(self.node, self.tree)).unwrap()
}

///|
#borrow(node, tree)
extern "c" fn ts_node_grammar_symbol(node : TSNode, tree : TSTree) -> Symbol = "moonbit_ts_node_grammar_symbol"

///|
/// Get the node's type as a numerical id as it appears in the grammar ignoring
/// aliases. This should be used in `Language::next_state` instead of
/// `Node::symbol`.
pub fn Node::grammar_symbol(self : Node) -> Symbol {
  return ts_node_grammar_symbol(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_start_byte(node : TSNode, tree : TSTree) -> Int = "moonbit_ts_node_start_byte"

///|
/// Get the node's start byte.
pub fn Node::start_byte(self : Node) -> Int {
  return ts_node_start_byte(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_start_point(node : TSNode, tree : TSTree) -> Point = "moonbit_ts_node_start_point"

///|
/// Get the node's start position in terms of rows and columns.
pub fn Node::start_point(self : Node) -> Point {
  return ts_node_start_point(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_end_byte(node : TSNode, tree : TSTree) -> Int = "moonbit_ts_node_end_byte"

///|
/// Get the node's end byte.
pub fn Node::end_byte(self : Node) -> Int {
  return ts_node_end_byte(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_string(node : TSNode, tree : TSTree) -> Bytes = "moonbit_ts_node_string"

///|
/// Get the node's end position in terms of rows and columns.
#borrow(node, tree)
extern "c" fn ts_node_end_point(node : TSNode, tree : TSTree) -> Point = "moonbit_ts_node_end_point"

///|
pub fn Node::end_point(self : Node) -> Point {
  return ts_node_end_point(self.node, self.tree)
}

///|
pub fn Node::range(self : Node) -> Range {
  return Range::new(
    self.start_point(),
    self.end_point(),
    self.start_byte(),
    self.end_byte(),
  )
}

///|
/// Get an S-expression representing the node as a string.
pub fn Node::string(self : Node) -> String {
  return @encoding.decode_lossy(
    encoding=UTF8,
    ts_node_string(self.node, self.tree),
  )
}

///|
pub impl Show for Node with output(self : Node, logger : &@builtin.Logger) -> Unit {
  try @sexp.parse(self.string()) |> @sexp.print_to(logger) catch {
    _ => logger.write_string(self.string().to_string())
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_is_null(node : TSNode, tree : TSTree) -> Bool = "moonbit_ts_node_is_null"

///|
/// Check if the node is null. Functions like `Node::child` and
/// `Node::next_sibling` will return a null node to indicate that no such node
/// was found.
pub fn Node::is_null(self : Node) -> Bool {
  return ts_node_is_null(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_is_named(node : TSNode, tree : TSTree) -> Bool = "moonbit_ts_node_is_named"

///|
/// Check if the node is *named*. Named nodes correspond to named rules in the
/// grammar, whereas *anonymous* nodes correspond to string literals in the
/// grammar.
pub fn Node::is_named(self : Node) -> Bool {
  return ts_node_is_named(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_is_missing(node : TSNode, tree : TSTree) -> Bool = "moonbit_ts_node_is_missing"

///|
/// Check if the node is *missing*. Missing nodes are inserted by the parser in
/// order to recover from certain kinds of syntax errors.
pub fn Node::is_missing(self : Node) -> Bool {
  return ts_node_is_missing(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_is_extra(node : TSNode, tree : TSTree) -> Bool = "moonbit_ts_node_is_extra"

///|
/// Check if the node is *extra*. Extra nodes represent things like comments,
/// which are not required the grammar, but can appear anywhere.
pub fn Node::is_extra(self : Node) -> Bool {
  return ts_node_is_extra(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_has_changes(node : TSNode, tree : TSTree) -> Bool = "moonbit_ts_node_has_changes"

///|
/// Check if a syntax node has been edited.
pub fn Node::has_changes(self : Node) -> Bool {
  return ts_node_has_changes(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_has_error(node : TSNode, tree : TSTree) -> Bool = "moonbit_ts_node_has_error"

///|
/// Check if the node is a syntax error or contains any syntax errors.
pub fn Node::has_error(self : Node) -> Bool {
  return ts_node_has_error(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_is_error(node : TSNode, tree : TSTree) -> Bool = "moonbit_ts_node_is_error"

///|
/// Check if the node is a syntax error.
pub fn Node::is_error(self : Node) -> Bool {
  return ts_node_is_error(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_parse_state(node : TSNode, tree : TSTree) -> StateId = "moonbit_ts_node_parse_state"

///|
/// Get this node's parse state.
pub fn Node::parse_state(self : Node) -> StateId {
  return ts_node_parse_state(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_next_parse_state(node : TSNode, tree : TSTree) -> StateId = "moonbit_ts_node_next_parse_state"

///|
/// Get the parse state after this node.
pub fn Node::next_parse_state(self : Node) -> StateId {
  return ts_node_next_parse_state(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_parent(node : TSNode, tree : TSTree) -> TSNode = "moonbit_ts_node_parent"

///|
/// Get the node's immediate parent.
/// Prefer `Node::child_with_descendant` for iterating over the node's ancestors.
pub fn Node::parent(self : Node) -> Node? {
  let parent = ts_node_parent(self.node, self.tree)
  if ts_node_is_null(parent, self.tree) {
    None
  } else {
    Some({ ..self, node: parent })
  }
}

///|
#borrow(node, self_tree, descendant, descendant_tree)
extern "c" fn ts_node_child_with_descendant(
  node : TSNode,
  self_tree : TSTree,
  descendant : TSNode,
  descendant_tree : TSTree,
) -> TSNode = "moonbit_ts_node_child_with_descendant"

///|
/// Get the node that contains `descendant`.
///
/// Note that this can return `descendant` itself.
pub fn Node::child_with_descendant(self : Node, descendant : Node) -> Node? {
  let child = ts_node_child_with_descendant(
    self.node,
    self.tree,
    descendant.node,
    descendant.tree,
  )
  if ts_node_is_null(child, self.tree) {
    None
  } else {
    Some({ ..self, node: child })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_child(
  node : TSNode,
  tree : TSTree,
  index : UInt,
) -> TSNode = "moonbit_ts_node_child"

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
  let child = ts_node_child(self.node, self.tree, index)
  if ts_node_is_null(child, self.tree) {
    None
  } else {
    Some({ ..self, node: child })
  }
}

///|
/// Get all children of the node.
pub fn Node::children(self : Node) -> Iter[Node] {
  Iter::new(fn(yield_) {
    for i in 0U..<ts_node_child_count(self.node, self.tree) {
      let child = ts_node_child(self.node, self.tree, i)
      match yield_({ ..self, node: child }) {
        IterEnd => return IterEnd
        IterContinue => continue
      }
    }
    IterContinue
  })
}

///|
#borrow(node, tree)
extern "c" fn ts_node_field_name_for_child(
  node : TSNode,
  tree : TSTree,
  child_index : UInt,
) -> @native.ConstPtr[Byte] = "moonbit_ts_node_field_name_for_child"

///|
/// Get the field name for node's child at the given index, where zero represents
/// the first child. Returns `None`, if no field is found.
pub fn Node::field_name_for_child(self : Node, child_index : Int) -> String? {
  let child_index = int_to_uint(child_index)
  let field_name = ts_node_field_name_for_child(
    self.node,
    self.tree,
    child_index,
  )
  decode_c_string(field_name)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_field_name_for_named_child(
  node : TSNode,
  tree : TSTree,
  child_index : UInt,
) -> @native.ConstPtr[Byte] = "moonbit_ts_node_field_name_for_named_child"

///|
/// Get the field name for node's named child at the given index, where zero
/// represents the first named child. Returns `None`, if no field is found.
pub fn Node::field_name_for_named_child(
  self : Node,
  child_index : Int,
) -> String? {
  let child_index = int_to_uint(child_index)
  let field_name = ts_node_field_name_for_named_child(
    self.node,
    self.tree,
    child_index,
  )
  decode_c_string(field_name)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_child_count(node : TSNode, tree : TSTree) -> UInt = "moonbit_ts_node_child_count"

///|
/// Get the node's number of children.
pub fn Node::child_count(self : Node) -> Int {
  uint_to_int(ts_node_child_count(self.node, self.tree))
}

///|
#borrow(node, tree)
extern "c" fn ts_node_named_child(
  node : TSNode,
  tree : TSTree,
  child_index : UInt,
) -> TSNode = "moonbit_ts_node_named_child"

///|
/// Get the node's *named* child at the given index.
///
/// See also `Node::is_named`.
pub fn Node::named_child(self : Node, child_index : Int) -> Node? {
  let child_index = int_to_uint(child_index)
  let child = ts_node_named_child(self.node, self.tree, child_index)
  if ts_node_is_null(child, self.tree) {
    None
  } else {
    Some({ ..self, node: child })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_named_child_count(node : TSNode, tree : TSTree) -> UInt = "moonbit_ts_node_named_child_count"

///|
/// Get the node's number of *named* children.
///
/// See also `Node::is_named`.
pub fn Node::named_child_count(self : Node) -> Int {
  uint_to_int(ts_node_named_child_count(self.node, self.tree))
}

///|
/// Get all named children of the node.
pub fn Node::named_children(self : Node) -> Iter[Node] {
  Iter::new(fn(yield_) {
    for i in 0U..<ts_node_named_child_count(self.node, self.tree) {
      let child = ts_node_named_child(self.node, self.tree, i)
      match yield_({ ..self, node: child }) {
        IterEnd => return IterEnd
        IterContinue => continue
      }
    }
    IterContinue
  })
}

///|
/// Get the node's child with the given field name.
#borrow(node, tree, name)
extern "c" fn ts_node_child_by_field_name(
  node : TSNode,
  tree : TSTree,
  name : Bytes,
) -> TSNode = "moonbit_ts_node_child_by_field_name"

///|
/// Get the node's child with the given field name.
pub fn Node::child_by_field_name(self : Node, name : @string.View) -> Node? {
  let name_bytes = @encoding.encode(encoding=UTF8, name)
  let child = ts_node_child_by_field_name(self.node, self.tree, name_bytes)
  if ts_node_is_null(child, self.tree) {
    None
  } else {
    Some({ ..self, node: child })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_child_by_field_id(
  node : TSNode,
  tree : TSTree,
  id : FieldId,
) -> TSNode = "moonbit_ts_node_child_by_field_id"

///|
/// Get the node's child with the given numerical field id.
///
/// You can convert a field name to an id using the
/// `Language::field_id_for_name` function.
pub fn Node::child_by_field_id(self : Node, id : FieldId) -> Node? {
  let child = ts_node_child_by_field_id(self.node, self.tree, id)
  if ts_node_is_null(child, self.tree) {
    None
  } else {
    Some({ ..self, node: child })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_next_sibling(node : TSNode, tree : TSTree) -> TSNode = "moonbit_ts_node_next_sibling"

///|
/// Get the node's next sibling.
pub fn Node::next_sibling(self : Node) -> Node? {
  let next_sibling = ts_node_next_sibling(self.node, self.tree)
  if ts_node_is_null(next_sibling, self.tree) {
    None
  } else {
    Some({ ..self, node: next_sibling })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_prev_sibling(node : TSNode, tree : TSTree) -> TSNode = "moonbit_ts_node_prev_sibling"

///|
/// Get the node's previous sibling.
pub fn Node::prev_sibling(self : Node) -> Node? {
  let prev_sibling = ts_node_prev_sibling(self.node, self.tree)
  if ts_node_is_null(prev_sibling, self.tree) {
    None
  } else {
    Some({ ..self, node: prev_sibling })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_next_named_sibling(
  node : TSNode,
  tree : TSTree,
) -> TSNode = "moonbit_ts_node_next_named_sibling"

///|
/// Get the node's next *named* sibling.
pub fn Node::next_named_sibling(self : Node) -> Node? {
  let next_named_sibling = ts_node_next_named_sibling(self.node, self.tree)
  if ts_node_is_null(next_named_sibling, self.tree) {
    None
  } else {
    Some({ ..self, node: next_named_sibling })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_prev_named_sibling(
  node : TSNode,
  tree : TSTree,
) -> TSNode = "moonbit_ts_node_prev_named_sibling"

///|
/// Get the node's previous *named* sibling.
pub fn Node::prev_named_sibling(self : Node) -> Node? {
  let prev_named_sibling = ts_node_prev_named_sibling(self.node, self.tree)
  if ts_node_is_null(prev_named_sibling, self.tree) {
    None
  } else {
    Some({ ..self, node: prev_named_sibling })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_first_child_for_byte(
  node : TSNode,
  tree : TSTree,
  byte : UInt,
) -> TSNode = "moonbit_ts_node_first_child_for_byte"

///|
/// Get the node's first child that contains or starts after the given byte offset.
pub fn Node::first_child_for_byte(self : Node, byte : Int) -> Node? {
  let byte = int_to_uint(byte)
  let child = ts_node_first_child_for_byte(self.node, self.tree, byte)
  if ts_node_is_null(child, self.tree) {
    None
  } else {
    Some({ ..self, node: child })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_first_named_child_for_byte(
  node : TSNode,
  tree : TSTree,
  byte : UInt,
) -> TSNode = "moonbit_ts_node_first_named_child_for_byte"

///|
/// Get the node's first named child that contains or starts after the given byte offset.
pub fn Node::first_named_child_for_byte(self : Node, byte : Int) -> Node? {
  let byte = int_to_uint(byte)
  let child = ts_node_first_named_child_for_byte(self.node, self.tree, byte)
  if ts_node_is_null(child, self.tree) {
    None
  } else {
    Some({ ..self, node: child })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_descendant_count(node : TSNode, tree : TSTree) -> Int = "moonbit_ts_node_descendant_count"

///|
/// Get the node's number of descendants, including one for the node itself.
pub fn Node::descendant_count(self : Node) -> Int {
  return ts_node_descendant_count(self.node, self.tree)
}

///|
#borrow(node, tree)
extern "c" fn ts_node_descendant_for_byte_range(
  node : TSNode,
  tree : TSTree,
  start_byte : UInt,
  end_byte : UInt,
) -> TSNode = "moonbit_ts_node_descendant_for_byte_range"

///|
/// Get the smallest node within this node that spans the given range of bytes.
pub fn Node::descendant_for_byte_range(
  self : Node,
  start_byte : Int,
  end_byte : Int,
) -> Node? {
  let start_byte = int_to_uint(start_byte)
  let end_byte = int_to_uint(end_byte)
  let descendant = ts_node_descendant_for_byte_range(
    self.node,
    self.tree,
    start_byte,
    end_byte,
  )
  if ts_node_is_null(descendant, self.tree) {
    None
  } else {
    Some({ ..self, node: descendant })
  }
}

///|
#borrow(node, tree, start_point, end_point)
extern "c" fn ts_node_descendant_for_point_range(
  node : TSNode,
  tree : TSTree,
  start_point : Point,
  end_point : Point,
) -> TSNode = "moonbit_ts_node_descendant_for_point_range"

///|
/// Get the smallest node within this node that spans the given range of
/// (row, column) positions.
pub fn Node::descendant_for_point_range(
  self : Node,
  start_point : Point,
  end_point : Point,
) -> Node? {
  let descendant = ts_node_descendant_for_point_range(
    self.node,
    self.tree,
    start_point,
    end_point,
  )
  if ts_node_is_null(descendant, self.tree) {
    None
  } else {
    Some({ ..self, node: descendant })
  }
}

///|
#borrow(node, tree)
extern "c" fn ts_node_named_descendant_for_byte_range(
  node : TSNode,
  tree : TSTree,
  start_byte : UInt,
  end_byte : UInt,
) -> TSNode = "moonbit_ts_node_named_descendant_for_byte_range"

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
    self.node,
    self.tree,
    start_byte,
    end_byte,
  )
  if ts_node_is_null(descendant, self.tree) {
    None
  } else {
    Some({ ..self, node: descendant })
  }
}

///|
#borrow(node, tree, start_point, end_point)
extern "c" fn ts_node_named_descendant_for_point_range(
  node : TSNode,
  tree : TSTree,
  start_point : Point,
  end_point : Point,
) -> TSNode = "moonbit_ts_node_named_descendant_for_point_range"

///|
/// Get the smallest named node within this node that spans the given
/// (row, column) positions.
pub fn Node::named_descendant_for_point_range(
  self : Node,
  start_point : Point,
  end_point : Point,
) -> Node? {
  let descendant = ts_node_named_descendant_for_point_range(
    self.node,
    self.tree,
    start_point,
    end_point,
  )
  if ts_node_is_null(descendant, self.tree) {
    None
  } else {
    Some({ ..self, node: descendant })
  }
}

///|
#borrow(node, tree, edit)
extern "c" fn ts_node_edit(node : TSNode, tree : TSTree, edit : InputEdit) = "moonbit_ts_node_edit"

///|
/// Edit the node to keep it in-sync with source code that has been edited.
///
/// This function is only rarely needed. When you edit a syntax tree with the
/// `Tree::edit` function, all of the nodes that you retrieve from the tree
/// afterward will already reflect the edit. You only need to use `Node::edit`
/// when you have a `Node` instance that you want to keep and continue to use
/// after an edit.
pub fn Node::edit(self : Node, edit : InputEdit) -> Unit {
  ts_node_edit(self.node, self.tree, edit)
}

///|
#borrow(node, self_tree, other, other_tree)
extern "c" fn ts_node_eq(
  node : TSNode,
  self_tree : TSTree,
  other : TSNode,
  other_tree : TSTree,
) -> Bool = "moonbit_ts_node_eq"

///|
/// Check if two nodes are identical.
pub fn Node::eq(self : Node, other : Node) -> Bool {
  ts_node_eq(self.node, self.tree, other.node, other.tree)
}

///|
pub impl Eq for Node with op_equal(self, other) -> Bool {
  ts_node_eq(self.node, self.tree, other.node, other.tree)
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
#borrow(self)
extern "c" fn Node::id_as_uint64(self : TSNode, tree : TSTree) -> UInt64 = "moonbit_ts_node_id_as_uint64"

///|
pub impl Hash for Node with hash_combine(self, hasher) {
  let id = Node::id_as_uint64(self.node, self.tree)
  hasher.combine(id)
}

///|
pub fn Node::walk(self : Node) -> TreeCursor {
  TreeCursor::new(self)
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

///|
pub fn Node::text(self : Node) -> @string.View {
  let start = self.start_byte()
  let end = self.end_byte()
  let text = self.text.view(start_offset=start, end_offset=end)
  return text
}

///|
pub fn Node::symbols(self : Node) -> Iter[Symbol] {
  let iterator = LookaheadIterator::new(self.language(), self.parse_state())
  guard iterator is Some(iterator) else { Iter::empty() }
  Iter::new(fn(yield_) {
    while iterator.next() {
      let symbol = iterator.current_symbol()
      match yield_(symbol) {
        IterEnd => break IterEnd
        IterContinue => continue
      }
    } else {
      IterContinue
    }
  })
}

///|
pub fn Node::symbol_names(self : Node) -> Iter[String] {
  let language = self.language()
  Iter::new(fn(yield_) {
    for symbol in self.symbols() {
      guard language.symbol_name(symbol) is Some(name) else { continue }
      match yield_(name) {
        IterContinue => continue
        IterEnd => break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
pub fn Node::next_symbols(self : Node) -> Iter[Symbol] {
  let iterator = LookaheadIterator::new(
    self.language(),
    self.next_parse_state(),
  )
  guard iterator is Some(iterator) else { Iter::empty() }
  Iter::new(fn(yield_) {
    while iterator.next() {
      let symbol = iterator.current_symbol()
      match yield_(symbol) {
        IterEnd => break IterEnd
        IterContinue => continue
      }
    } else {
      IterContinue
    }
  })
}

///|
pub fn Node::next_symbol_names(self : Node) -> Iter[String] {
  let language = self.language()
  Iter::new(fn(yield_) {
    for symbol in self.next_symbols() {
      guard language.symbol_name(symbol) is Some(name) else { continue }
      match yield_(name) {
        IterContinue => continue
        IterEnd => break IterEnd
      }
    } else {
      IterContinue
    }
  })
}
