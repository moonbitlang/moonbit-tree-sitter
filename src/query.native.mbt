///|
type Query

///|
extern "c" fn ts_query_null() -> Query = "moonbit_c_null"

///|
suberror QueryError {
  Syntax(UInt)
  NodeType(UInt)
  Field(UInt)
  Capture(UInt)
  Structure(UInt)
  Language(UInt)
} derive(Show, ToJson)

///|
fn QueryError::offset(self : QueryError) -> UInt {
  match self {
    QueryError::Syntax(offset) => offset
    QueryError::NodeType(offset) => offset
    QueryError::Field(offset) => offset
    QueryError::Capture(offset) => offset
    QueryError::Structure(offset) => offset
    QueryError::Language(offset) => offset
  }
}

///|
fn QueryError::from(offset : UInt, type_ : UInt) -> QueryError {
  match type_ {
    1 => QueryError::Syntax(offset)
    2 => QueryError::NodeType(offset)
    3 => QueryError::Field(offset)
    4 => QueryError::Capture(offset)
    5 => QueryError::Structure(offset)
    6 => QueryError::Language(offset)
    type_ => abort("Invalid QueryError type: \{type_}")
  }
}

///|
#borrow(source, error)
extern "c" fn ts_query_new(
  language : Language,
  source : Bytes,
  error : FixedArray[UInt]
) -> Query = "moonbit_ts_query_new"

///|
/// Create a new query from a string containing one or more S-expression
/// patterns. The query is associated with a particular language, and can
/// only be run on syntax nodes parsed with that language.
///
/// If all of the given patterns are valid, this returns a `Query`.
/// If a pattern is invalid, this raises a `QueryError`.
pub fn Query::new(
  language : Language,
  source : @string.View
) -> Query raise QueryError {
  let error = FixedArray::make(2, 0U)
  let source = @encoding.encode(encoding=UTF8, source)
  let query = ts_query_new(language, source, error)
  if error[1] == 0 {
    query
  } else {
    raise QueryError::from(error[0], error[1])
  }
}

///|
/// Get the number of patterns in the query.
#borrow(query)
extern "c" fn ts_query_pattern_count(query : Query) -> UInt = "moonbit_ts_query_pattern_count"

///|
/// Get the number of patterns in the query.
pub fn Query::pattern_count(self : Query) -> Int {
  uint_to_int(ts_query_pattern_count(self))
}

///|
/// Get the number of captures in the query.
#borrow(query)
extern "c" fn ts_query_capture_count(query : Query) -> UInt = "moonbit_ts_query_capture_count"

///|
/// Get the number of captures in the query.
pub fn Query::capture_count(self : Query) -> Int {
  uint_to_int(ts_query_capture_count(self))
}

///|
/// Get the number of string literals in the query.
#borrow(query)
extern "c" fn ts_query_string_count(query : Query) -> UInt = "moonbit_ts_query_string_count"

///|
/// Get the number of string literals in the query.
pub fn Query::string_count(self : Query) -> Int {
  uint_to_int(ts_query_string_count(self))
}

///|
#borrow(query)
extern "c" fn ts_query_start_byte_for_pattern(
  query : Query,
  pattern_index : UInt
) -> UInt = "moonbit_ts_query_start_byte_for_pattern"

///|
/// Get the byte offset where the given pattern starts in the query's source.
///
/// This can be useful when combining queries by concatenating their source
/// code strings.
pub fn Query::start_byte_for_pattern(self : Query, pattern_index : Int) -> Int {
  let pattern_index = int_to_uint(pattern_index)
  ts_query_start_byte_for_pattern(self, pattern_index) |> uint_to_int()
}

///|
#borrow(query)
extern "c" fn ts_query_end_byte_for_pattern(
  query : Query,
  pattern_index : UInt
) -> UInt = "moonbit_ts_query_end_byte_for_pattern"

///|
/// Get the byte offset where the given pattern ends in the query's source.
///
/// This can be useful when combining queries by concatenating their source
/// code strings.
pub fn Query::end_byte_for_pattern(self : Query, pattern_index : Int) -> Int {
  let pattern_index = int_to_uint(pattern_index)
  ts_query_end_byte_for_pattern(self, pattern_index) |> uint_to_int()
}

///|
#borrow(query)
extern "c" fn ts_query_predicates_for_pattern(
  query : Query,
  pattern_index : UInt
) -> FixedArray[UInt] = "moonbit_ts_query_predicates_for_pattern"

///|
priv enum QueryPredicateStepType {
  Done
  Capture
  String
} derive(Show)

///|
fn QueryPredicateStepType::of_uint(value : UInt) -> QueryPredicateStepType {
  match value {
    0 => QueryPredicateStepType::Done
    1 => QueryPredicateStepType::Capture
    2 => QueryPredicateStepType::String
    value => abort("Invalid QueryPredicateStepType: \{value}")
  }
}

///|
pub enum QueryPredicateStep {
  Capture(String)
  String(String)
}

///|
pub impl Show for QueryPredicateStep with output(
  self,
  logger : &@builtin.Logger
) -> Unit {
  match self {
    Capture(name) => logger.write_string("@\{name}")
    String(value) => logger.write_string(value.escape())
  }
}

///|
pub impl ToJson for QueryPredicateStep with to_json(self) -> Json {
  self.to_string().to_json()
}

///|
pub typealias Array[QueryPredicateStep] as QueryPredicate

///|
/// Get all of the predicates for the given pattern in the query.
///
/// The predicates are represented as a single array of array of steps.
/// There are two types of steps in this array:
/// - `QueryPredicateStep::Capture` - Steps with this type represent names
///    of captures. Their `value_id` can be used with the
///    `Query::capture_name_for_id` function to obtain the name of the capture.
/// - `QueryPredicateStep::String` - Steps with this type represent literal
///    strings. Their `value_id` can be used with the
///    `Query::string_value_for_id` function to obtain their string value.
pub fn Query::predicates_for_pattern(
  self : Query,
  pattern_index : Int
) -> Array[QueryPredicate] {
  let pattern_index = int_to_uint(pattern_index)
  let flatten_predicates = ts_query_predicates_for_pattern(self, pattern_index)
  let predicates = []
  let mut predicate = []
  for i in 0..<(flatten_predicates.length() / 2) {
    let value = flatten_predicates[i * 2 + 1]
    let value = uint_to_int(value)
    let type_ = QueryPredicateStepType::of_uint(flatten_predicates[i * 2])
    match type_ {
      Capture => {
        let name = Query::capture_name_for_id(self, value)
        predicate.push(QueryPredicateStep::Capture(name))
      }
      String => {
        let value = Query::string_value_for_id(self, value).unwrap()
        predicate.push(QueryPredicateStep::String(value))
      }
      Done => {
        predicates.push(predicate)
        predicate = []
      }
    }
  }
  predicates
}

///|
#borrow(query)
extern "c" fn ts_query_is_pattern_rooted(
  query : Query,
  pattern_index : UInt
) -> Bool = "moonbit_ts_query_is_pattern_rooted"

///|
/// Check if the given pattern in the query has a single root node.
pub fn Query::is_pattern_rooted(self : Query, pattern_index : Int) -> Bool {
  ts_query_is_pattern_rooted(self, int_to_uint(pattern_index))
}

///|
#borrow(query)
extern "c" fn ts_query_is_pattern_non_local(
  query : Query,
  pattern_index : UInt
) -> Bool = "moonbit_ts_query_is_pattern_non_local"

///|
/// Check if the given pattern in the query is 'non local'.
///
/// A non-local pattern has multiple root nodes and can match within a
/// repeating sequence of nodes, as specified by the grammar. Non-local
/// patterns disable certain optimizations that would otherwise be possible
/// when executing a query on a specific range of a syntax tree.
pub fn Query::is_pattern_non_local(self : Query, pattern_index : Int) -> Bool {
  ts_query_is_pattern_non_local(self, int_to_uint(pattern_index))
}

///|
#borrow(query)
extern "c" fn ts_query_is_pattern_guaranteed_at_step(
  query : Query,
  byte_offset : UInt
) -> Bool = "moonbit_ts_query_is_pattern_guaranteed_at_step"

///|
/// Check if a given pattern is guaranteed to match once a given step is reached.
/// The step is specified by its byte offset in the query's source code.
pub fn Query::is_pattern_guaranteed_at_step(
  self : Query,
  byte_offset : Int
) -> Bool {
  ts_query_is_pattern_guaranteed_at_step(self, int_to_uint(byte_offset))
}

///|
#borrow(query, length)
extern "c" fn ts_query_capture_name_for_id(
  query : Query,
  capture_id : UInt,
  length : FixedArray[UInt]
) -> @native.ConstPtr[Byte] = "moonbit_ts_query_capture_name_for_id"

///|
/// Get the name of one of the query's captures. Each capture is associated with a
/// numeric id based on the order that it appeared in the query's source.
pub fn Query::capture_name_for_id(self : Query, capture_id : Int) -> String {
  let capture_id = int_to_uint(capture_id)
  let length : FixedArray[UInt] = [0U]
  let name = ts_query_capture_name_for_id(self, capture_id, length)
  return decode_c_string(name, length=length[0].reinterpret_as_int()).unwrap()
}

///|
pub enum Quantifier {
  Zero
  ZeroOrOne
  ZeroOrMore
  One
  OneOrMore
} derive(Show)

///|
fn Quantifier::of_uint(value : UInt) -> Quantifier {
  match value {
    0 => Quantifier::Zero
    1 => Quantifier::ZeroOrOne
    2 => Quantifier::ZeroOrMore
    3 => Quantifier::One
    4 => Quantifier::OneOrMore
    value => abort("Invalid Quantifier: \{value}")
  }
}

#borrow(query)
extern "c" fn ts_query_capture_quantifier_for_id(
  query : Query,
  pattern_index : UInt,
  capture_index : UInt
) -> UInt = "moonbit_ts_query_capture_quantifier_for_id"

///|
/// Get the quantifier of the query's captures. Each capture is
/// associated with a numeric id based on the order that it appeared in the query's source.
pub fn Query::capture_quantifier_for_id(
  self : Query,
  pattern_index : Int,
  capture_index : Int
) -> Quantifier {
  let pattern_index = int_to_uint(pattern_index)
  let capture_index = int_to_uint(capture_index)
  Quantifier::of_uint(
    ts_query_capture_quantifier_for_id(self, pattern_index, capture_index),
  )
}

///|
#borrow(query)
extern "c" fn ts_query_string_value_for_id(
  query : Query,
  string_id : UInt
) -> @c.Nullable[Bytes] = "moonbit_ts_query_string_value_for_id"

///|
/// Get the value of one of the query's string literals. Each string is associated with a
/// numeric id based on the order that it appeared in the query's source.
pub fn Query::string_value_for_id(self : Query, string_id : Int) -> String? {
  let string_id = int_to_uint(string_id)
  let value = ts_query_string_value_for_id(self, string_id).to()
  guard value is Some(value) else { return None }
  Some(@encoding.decode_lossy(value, encoding=UTF8))
}

///|
#borrow(query, name)
extern "c" fn ts_query_disable_capture(query : Query, name : Bytes) = "moonbit_ts_query_disable_capture"

///|
/// Disable a certain capture within a query.
///
/// This prevents the capture from being returned in matches, and also avoids
/// any resource usage associated with recording the capture. Currently, there
/// is no way to undo this.
pub fn Query::disable_capture(self : Query, name : @string.View) -> Unit {
  let name = @encoding.encode(encoding=UTF8, name)
  ts_query_disable_capture(self, name)
}

///|
#borrow(query)
extern "c" fn ts_query_disable_pattern(query : Query, pattern_index : UInt) = "moonbit_ts_query_disable_pattern"

///|
/// Disable a certain pattern within a query.
///
/// This prevents the pattern from matching and removes most of the overhead
/// associated with the pattern. Currently, there is no way to undo this.
pub fn Query::disable_pattern(self : Query, pattern_index : Int) -> Unit {
  ts_query_disable_pattern(self, int_to_uint(pattern_index))
}

///|
pub fn Query::matches(self : Query, node : Node) -> Iter[QueryMatch] {
  let cursor = QueryCursor::new()
  cursor.exec(self, node)
  cursor.matches()
}

///|
pub fn Query::captures(self : Query, node : Node) -> Iter[QueryCapture] {
  let cursor = QueryCursor::new()
  cursor.exec(self, node)
  cursor.captures()
}
