///|
priv type TSQueryCursor

///|
struct QueryCursor {
  cursor : TSQueryCursor
  mut query : Query
  mut tree : TSTree
  mut text : @string.View
}

///|
extern "c" fn ts_query_cursor_new() -> TSQueryCursor = "moonbit_ts_query_cursor_new"

///|
/// Create a new cursor for executing a given query.
///
/// The cursor stores the state that is needed to iteratively search for
/// matches. To use the query cursor, first call `QueryCursor::exec`
/// to start running a given query on a given syntax node. Then, there are
/// two options for consuming the results of the query:
/// 1. Repeatedly call `QueryCursor::next_match` to iterate over all of the
///    *matches* in the order that they were found. Each match contains the
///    index of the pattern that matched, and an array of captures. Because
///    multiple patterns can match the same set of nodes, one match may contain
///    captures that appear *before* some of the captures from a previous match.
/// 2. Repeatedly call `QueryCursor::next_capture` to iterate over all of the
///    individual *captures* in the order that they appear. This is useful if
///    don't care about which pattern matched, and just want a single ordered
///    sequence of captures.
///
/// If you don't care about consuming all of the results, you can stop calling
/// `QueryCursor::next_match` or `QueryCursor::next_capture` at any point.
/// You can then start executing another query on another node by calling
/// `QueryCursor::exec` again.
pub fn QueryCursor::new() -> QueryCursor {
  let cursor = ts_query_cursor_new()
  let cursor = QueryCursor::{
    cursor,
    query: ts_query_null(),
    tree: ts_tree_null(),
    text: "",
  }
  cursor
}

///|
#borrow(cursor, query, node, tree)
extern "c" fn ts_query_cursor_exec(
  cursor : TSQueryCursor,
  query : Query,
  node : TSNode,
  tree : TSTree
) = "moonbit_ts_query_cursor_exec"

///|
#borrow(cursor, query, node, tree)
extern "c" fn ts_query_cursor_exec_with_options(
  cursor : TSQueryCursor,
  query : Query,
  node : TSNode,
  tree : TSTree,
  progress_callback : (UInt) -> Unit
) = "moonbit_ts_query_cursor_exec_with_options"

///|
pub struct QueryCursorState {
  current_byte_offset : Int
}

///|
struct QueryCursorOptions {
  progress_callback : (QueryCursorState) -> Unit
}

///|
pub fn QueryCursorOptions::new(
  progress_callback~ : (QueryCursorState) -> Unit
) -> QueryCursorOptions {
  QueryCursorOptions::{ progress_callback, }
}

///|
/// Start running a given query on a given node, with optional options.
pub fn QueryCursor::exec(
  self : QueryCursor,
  query : Query,
  node : Node,
  options? : QueryCursorOptions
) -> Unit {
  match options {
    None => ts_query_cursor_exec(self.cursor, query, node.node, node.tree)
    Some(options) =>
      ts_query_cursor_exec_with_options(
        self.cursor,
        query,
        node.node,
        node.tree,
        fn(current_byte_offset) {
          let current_byte_offset = uint_to_int(current_byte_offset)
          (options.progress_callback)(QueryCursorState::{ current_byte_offset, })
        },
      )
  }
  self.query = query
  self.tree = node.tree
  self.text = node.text
}

///|
#borrow(cursor)
extern "c" fn ts_query_cursor_did_exceed_match_limit(
  cursor : TSQueryCursor
) -> Bool = "moonbit_ts_query_cursor_did_exceed_match_limit"

///|
/// Check if the query cursor exceeded its match limit.
///
/// Query cursors have an optional maximum capacity for storing lists of
/// in-progress captures. If this capacity is exceeded, then the
/// earliest-starting match will silently be dropped to make room for further
/// matches. This maximum capacity is optional — by default, query cursors allow
/// any number of pending matches, dynamically allocating new space for them as
/// needed as the query is executed.
pub fn QueryCursor::did_exceed_match_limit(self : QueryCursor) -> Bool {
  ts_query_cursor_did_exceed_match_limit(self.cursor)
}

///|
#borrow(cursor)
extern "c" fn ts_query_cursor_match_limit(cursor : TSQueryCursor) -> UInt = "moonbit_ts_query_cursor_match_limit"

///|
/// Get the maximum number of in-progress matches allowed by this query cursor.
///
/// See `QueryCursor::did_exceed_match_limit`.
pub fn QueryCursor::match_limit(self : QueryCursor) -> Int {
  ts_query_cursor_match_limit(self.cursor) |> uint_to_int()
}

///|
#borrow(cursor)
extern "c" fn ts_query_cursor_set_match_limit(
  cursor : TSQueryCursor,
  limit : UInt
) = "moonbit_ts_query_cursor_set_match_limit"

///|
/// Set the maximum number of in-progress matches allowed by this query cursor.
///
/// See `QueryCursor::did_exceed_match_limit`.
pub fn QueryCursor::set_match_limit(self : QueryCursor, limit : Int) -> Unit {
  ts_query_cursor_set_match_limit(self.cursor, int_to_uint(limit))
}

///|
#borrow(cursor)
extern "c" fn ts_query_cursor_set_byte_range(
  cursor : TSQueryCursor,
  start_byte : UInt,
  end_byte : UInt
) = "moonbit_ts_query_cursor_set_byte_range"

///|
/// Set the range of bytes in which the query will be executed.
///
/// The query cursor will return matches that intersect with the given byte range.
/// This means that a match may be returned even if some of its captures fall
/// outside the specified range, as long as at least part of the match
/// overlaps with the range.
pub fn QueryCursor::set_byte_range(
  self : QueryCursor,
  start_byte : Int,
  end_byte : Int
) -> Unit {
  ts_query_cursor_set_byte_range(
    self.cursor,
    int_to_uint(start_byte),
    int_to_uint(end_byte),
  )
}

///|
#borrow(cursor, start_point, end_point)
extern "c" fn ts_query_cursor_set_point_range(
  cursor : TSQueryCursor,
  start_point : Point,
  end_point : Point
) = "moonbit_ts_query_cursor_set_point_range"

///|
/// Set the range of (row, column) positions in which the query will be executed.
///
/// The query cursor will return matches that intersect with the given point range.
/// This means that a match may be returned even if some of its captures fall
/// outside the specified range, as long as at least part of the match
/// overlaps with the range.
pub fn QueryCursor::set_point_range(
  self : QueryCursor,
  start_point : Point,
  end_point : Point
) -> Unit {
  ts_query_cursor_set_point_range(self.cursor, start_point, end_point)
}

///|
struct QueryCapture {
  query : Query
  node : Node
  index : Int
}

///|
pub impl Show for QueryCapture with output(self, logger) -> Unit {
  logger.write_string(self.node.string().to_string())
  logger.write_string(" @")
  logger.write_object(self.name())
}

///|
pub impl ToJson for QueryCapture with to_json(self) -> Json {
  Json::object({
    "name": self.name().to_json(),
    "node": self.node.to_string().to_json(),
    "index": self.index.to_json(),
  })
}

///|
pub fn QueryCapture::node(self : QueryCapture) -> Node {
  self.node
}

///|
pub fn QueryCapture::index(self : QueryCapture) -> Int {
  self.index
}

///|
pub fn QueryCapture::name(self : QueryCapture) -> String {
  self.query.capture_name_for_id(self.index)
}

///|
struct QueryMatch {
  query : Query
  id : Int
  pattern_index : Int
  captures : FixedArray[QueryCapture]
}

///|
pub impl ToJson for QueryMatch with to_json(self) -> Json {
  Json::object({
    "id": self.id.to_json(),
    "pattern_index": self.pattern_index.to_json(),
    "captures": self.captures.to_json(),
  })
}

///|
pub fn QueryMatch::id(self : QueryMatch) -> Int {
  self.id
}

///|
pub fn QueryMatch::pattern_index(self : QueryMatch) -> Int {
  self.pattern_index
}

///|
pub fn QueryMatch::captures(self : QueryMatch) -> Iter[QueryCapture] {
  self.captures.iter()
}

///|
pub fn QueryMatch::predicates(self : QueryMatch) -> Array[QueryPredicate] {
  self.query.predicates_for_pattern(self.pattern_index)
}

///|
priv type TSQueryMatch

///|
#borrow(query_match)
extern "c" fn ts_query_match_is_null(query_match : TSQueryMatch) -> Bool = "moonbit_c_is_null"

///|
impl Nullable for TSQueryMatch with is_null(self : TSQueryMatch) -> Bool {
  return ts_query_match_is_null(self)
}

///|
#borrow(query)
extern "c" fn ts_query_match_id(query : TSQueryMatch) -> UInt = "moonbit_ts_query_match_id"

///|
#borrow(match_)
extern "c" fn ts_query_match_pattern_index(match_ : TSQueryMatch) -> UInt = "moonbit_ts_query_match_pattern_index"

///|
#borrow(query_match)
extern "c" fn ts_query_match_capture_count(
  query_match : TSQueryMatch
) -> UInt16 = "moonbit_ts_query_match_capture_count"

///|
#borrow(query_match)
extern "c" fn ts_query_match_captures_get_node(
  query_match : TSQueryMatch,
  index : UInt
) -> TSNode = "moonbit_ts_query_match_captures_get_node"

///|
#borrow(query)
extern "c" fn ts_query_match_captures_get_index(
  query : TSQueryMatch,
  index : UInt
) -> UInt = "moonbit_ts_query_match_captures_get_index"

///|
#borrow(cursor, query, tree)
extern "c" fn ts_query_cursor_next_match(
  cursor : TSQueryCursor,
  query : Query,
  tree : TSTree
) -> TSQueryMatch = "moonbit_ts_query_cursor_next_match"

///|
/// Advance to the next match of the currently running query.
///
/// If there is a match, returns Some(match).
/// Otherwise, returns None.
pub fn QueryCursor::next_match(self : QueryCursor) -> QueryMatch? {
  let ts_match = ts_query_cursor_next_match(self.cursor, self.query, self.tree).to_option()
  guard ts_match is Some(ts_match) else { return None }
  let capture_count = ts_query_match_capture_count(ts_match)
  let captures = FixedArray::makei(capture_count.to_int(), fn(i) {
    let i = i.reinterpret_as_uint()
    let node = ts_query_match_captures_get_node(ts_match, i)
    let index = ts_query_match_captures_get_index(ts_match, i)
    let index = uint_to_int(index)
    QueryCapture::{
      query: self.query,
      node: { node, tree: self.tree, text: self.text },
      index,
    }
  })
  let id = uint_to_int(ts_query_match_id(ts_match))
  let pattern_index = uint_to_int(ts_query_match_pattern_index(ts_match))
  Some(QueryMatch::{ query: self.query, id, pattern_index, captures })
}

///|
pub fn QueryCursor::matches(self : QueryCursor) -> Iter[QueryMatch] {
  Iter::new(fn(yield_) {
    while self.next_match() is Some(match_) {
      match yield_(match_) {
        IterContinue => continue
        IterEnd => break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
#borrow(cursor, query, tree)
extern "c" fn ts_query_cursor_remove_match(
  cursor : TSQueryCursor,
  query : Query,
  tree : TSTree,
  match_id : UInt
) = "moonbit_ts_query_cursor_remove_match"

///|
/// Remove a match from the query cursor's results.
pub fn QueryCursor::remove_match(self : QueryCursor, match_id : Int) -> Unit {
  ts_query_cursor_remove_match(
    self.cursor,
    self.query,
    self.tree,
    int_to_uint(match_id),
  )
}

///|
#borrow(cursor, query, tree, match_id)
extern "c" fn ts_query_cursor_next_capture(
  cursor : TSQueryCursor,
  query : Query,
  tree : TSTree,
  match_id : FixedArray[UInt]
) -> @c.Nullable[TSQueryMatch] = "moonbit_ts_query_cursor_next_capture"

///|
/// Advance to the next capture of the currently running query.
///
/// If there is a capture, returns Some(capture).
/// Otherwise, returns None.
pub fn QueryCursor::next_capture(self : QueryCursor) -> QueryCapture? {
  let match_id = FixedArray::make(1, 0U)
  let ts_match = ts_query_cursor_next_capture(
    self.cursor,
    self.query,
    self.tree,
    match_id,
  ).to()
  guard ts_match is Some(ts_match) else { return None }
  let match_id = match_id[0]
  let node = ts_query_match_captures_get_node(ts_match, match_id)
  let node = { node, tree: self.tree, text: self.text }
  let index = ts_query_match_captures_get_index(ts_match, match_id)
  let index = uint_to_int(index)
  Some(QueryCapture::{ query: self.query, node, index })
}

///|
pub fn QueryCursor::captures(self : QueryCursor) -> Iter[QueryCapture] {
  Iter::new(fn(yield_) {
    while self.next_capture() is Some(capture) {
      match yield_(capture) {
        IterContinue => continue
        IterEnd => break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
#borrow(cursor)
extern "c" fn ts_query_cursor_set_max_start_depth(
  cursor : TSQueryCursor,
  max_start_depth : UInt
) = "moonbit_ts_query_cursor_set_max_start_depth"

///|
/// Set the maximum start depth for a query cursor.
///
/// This prevents cursors from exploring children nodes at a certain depth.
/// Note if a pattern includes many children, then they will still be checked.
///
/// The zero max start depth value can be used as a special behavior and
/// it helps to destructure a subtree by staying on a node and using captures
/// for interested parts. Note that the zero max start depth only limit a search
/// depth for a pattern's root node but other nodes that are parts of the pattern
/// may be searched at any depth what defined by the pattern structure.
///
/// Set to `@uint.max_value` to remove the maximum start depth.
pub fn QueryCursor::set_max_start_depth(
  self : QueryCursor,
  max_start_depth : Int
) -> Unit {
  ts_query_cursor_set_max_start_depth(self.cursor, int_to_uint(max_start_depth))
}
