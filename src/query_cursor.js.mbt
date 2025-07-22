///|
type QueryCapture

///|
pub extern "js" fn QueryCapture::pattern_index(self : QueryCapture) -> Int =
  #|(self) => {
  #|  return self.patternIndex;
  #|}

///|
pub extern "js" fn QueryCapture::name(self : QueryCapture) -> String =
  #|(self) => {
  #|  return self.name;
  #|}

///|
pub extern "js" fn QueryCapture::node(self : QueryCapture) -> Node =
  #|(self) => {
  #|  return self.node;
  #|}

///|
priv type TSQueryMatch

///|
extern "js" fn TSQueryMatch::captures(
  self : TSQueryMatch,
) -> Array[QueryCapture] =
  #|(self) => {
  #|  return self.captures;
  #|}

///|
extern "js" fn TSQueryMatch::pattern_index(self : TSQueryMatch) -> Int =
  #|(self) => {
  #|  return self.patternIndex;
  #|}

///|
struct QueryMatch {
  query : Query
  query_match : TSQueryMatch
}

///|
pub fn QueryMatch::captures(self : QueryMatch) -> Array[QueryCapture] {
  self.query_match.captures()
}

///|
pub fn QueryMatch::pattern_index(self : QueryMatch) -> Int {
  self.query_match.pattern_index()
}

///|
pub fn QueryMatch::predicates(self : QueryMatch) -> Array[QueryPredicate] {
  self.query.predicates_for_pattern(self.pattern_index())
}

///|
struct QueryCursor {
  mut query : Query?
  mut node : Node?
}

///|
pub fn QueryCursor::new() -> QueryCursor {
  QueryCursor::{ query: None, node: None }
}

///|
pub fn QueryCursor::exec(
  self : QueryCursor,
  query : Query,
  node : Node,
) -> Unit {
  self.query = Some(query)
  self.node = Some(node)
}

///|
pub fn QueryCursor::matches(self : QueryCursor) -> Iter[QueryMatch] {
  guard self.query is Some(query) && self.node is Some(node) else {
    Iter::empty()
  }
  query.matches(node).iter()
}
