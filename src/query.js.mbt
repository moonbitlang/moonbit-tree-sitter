///|
type Query

///|
extern "js" fn Query::null() -> Query =
  #|() => {
  #|  return null;
  #|}

///|
suberror QueryError {
  Syntax(UInt)
  NodeType(UInt)
  Field(UInt)
  Capture(UInt)
  Structure(UInt)
  Language(UInt)
} derive(Show)

///|
pub fn QueryError::offset(self : QueryError) -> UInt {
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
extern "js" fn ts_query_new(
  ts : TS,
  language : Language,
  source : String,
  error : FixedArray[UInt]
) -> Query =
  #|(ts, language, source, error) => {
  #|  try {
  #|    const query = new ts.Query(language, source);
  #|    error[1] = 0;
  #|    return query;
  #|  } catch (queryError) {
  #|    error[0] = queryError.index;
  #|    error[1] = queryError.type;
  #|    return null;
  #|  }
  #|}

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
  let query = ts_query_new(ts, language, source.to_string(), error)
  if error[1] == 0 {
    query
  } else {
    raise QueryError::from(error[0], error[1])
  }
}

///|
extern "js" fn ts_query_pattern_count(query : Query) -> UInt =
  #|() => {
  #|  return query.patternCount;
  #|}

///|
/// Get the number of patterns in the query.
pub fn Query::pattern_count(self : Query) -> Int {
  self |> ts_query_pattern_count() |> uint_to_int()
}

///|
extern "js" fn ts_query_capture_count(query : Query) -> UInt =
  #|(query) => {
  #|  return query.captureCount;
  #|}

///|
/// Get the number of captures in the query.
pub fn Query::capture_count(self : Query) -> Int {
  self |> ts_query_capture_count() |> uint_to_int()
}

///|
extern "js" fn ts_query_string_count(query : Query) -> UInt =
  #|(query) => {
  #|  return query.stringCount;
  #|}

///|
/// Get the number of string literals in the query.
pub fn Query::string_count(self : Query) -> Int {
  self |> ts_query_string_count() |> uint_to_int()
}

///|
extern "js" fn ts_query_start_byte_for_pattern(
  query : Query,
  pattern_index : UInt
) -> UInt =
  #|(query, patternIndex) => {
  #|  return query.startIndexForPattern(patternIndex);
  #|}

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
extern "js" fn ts_query_end_byte_for_pattern(
  query : Query,
  pattern_index : UInt
) -> UInt =
  #|(patternIndex) => {
  #|  return self.endIndexForPattern(patternIndex);
  #|}

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
priv enum QueryPredicateStepType {
  Capture
  String
} derive(Show)

///|
fn QueryPredicateStepType::of_string(value : String) -> QueryPredicateStepType {
  match value {
    "capture" => QueryPredicateStepType::Capture
    "string" => QueryPredicateStepType::String
    value => abort("Invalid QueryPredicateStepType: \{value}")
  }
}

///|
priv type TSQueryPredicateStep

///|
extern "js" fn TSQueryPredicateStep::type_(
  self : TSQueryPredicateStep
) -> String =
  #|(self) => {
  #|  return self.type;
  #|}

///|
extern "js" fn TSQueryPredicateStep::value(
  self : TSQueryPredicateStep
) -> String =
  #|(self) => {
  #|  if (self.type == "capture") {
  #|    return self.name;
  #|  } else if (self.type == "string") {
  #|    return self.value;
  #|  }
  #|}

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
priv type TSQueryPredicate

///|
extern "js" fn TSQueryPredicate::operator(self : TSQueryPredicate) -> String =
  #|(self) => {
  #|  return self.operator;
  #|}

///|
extern "js" fn TSQueryPredicate::operands(
  self : TSQueryPredicate
) -> Array[TSQueryPredicateStep] =
  #|(self) => {
  #|  return self.operands;
  #|}

///|
extern "js" fn ts_query_predicates_for_pattern(
  query : Query,
  pattern_index : Int
) -> Array[TSQueryPredicate] =
  #|(query, patternIndex) => {
  #|  return query.predicates[patternIndex];
  #|}

///|
typealias Array[QueryPredicateStep] as QueryPredicate

///|
pub fn Query::predicates_for_pattern(
  self : Query,
  pattern_index : Int
) -> Array[QueryPredicate] {
  let ts_predicates = ts_query_predicates_for_pattern(self, pattern_index)
  let predicates = []
  for ts_predicate in ts_predicates {
    let operator = ts_predicate.operator()
    let operands = ts_predicate.operands()
    let predicate = [QueryPredicateStep::String(operator)]
    for operand in operands {
      let type_ = QueryPredicateStepType::of_string(operand.type_())
      let value = operand.value()
      match type_ {
        QueryPredicateStepType::Capture =>
          predicate.push(QueryPredicateStep::Capture(value))
        QueryPredicateStepType::String =>
          predicate.push(QueryPredicateStep::String(value))
      }
    }
    predicates.push(predicate)
  }
  predicates
}

///|
extern "js" fn ts_query_is_pattern_rooted(
  query : Query,
  pattern_index : UInt
) -> Bool =
  #|(query, patternIndex) => {
  #|  return query.isPatternRooted(patternIndex);
  #|}

///|
/// Check if the given pattern in the query has a single root node.
pub fn Query::is_pattern_rooted(self : Query, pattern_index : Int) -> Bool {
  ts_query_is_pattern_rooted(self, int_to_uint(pattern_index))
}

///|
extern "js" fn ts_query_is_pattern_non_local(
  query : Query,
  pattern_index : UInt
) -> Bool =
  #|(query, patternIndex) => {
  #|  return query.isPatternNonLocal(patternIndex);
  #|}

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
extern "js" fn ts_query_is_pattern_guaranteed_at_step(
  query : Query,
  byte_offset : UInt
) -> Bool =
  #|(query, byteIndex) => {
  #|  return query.isPatternGuaranteedAtStep(byteIndex);
  #|}

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
extern "js" fn ts_query_capture_name_for_id(
  query : Query,
  capture_id : UInt
) -> String =
  #|(query, captureId) => {
  #|  return query.captureNames[captureId];
  #|}

///|
/// Get the name of one of the query's captures. Each capture is associated with a
/// numeric id based on the order that it appeared in the query's source.
pub fn Query::capture_name_for_id(
  self : Query,
  capture_id : Int
) -> @string.View {
  let capture_id = int_to_uint(capture_id)
  ts_query_capture_name_for_id(self, capture_id)
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

///|
extern "js" fn ts_query_capture_quantifier_for_id(
  query : Query,
  pattern_index : UInt,
  capture_index : UInt
) -> UInt =
  #|(query, patternIndex, captureIndex) => {
  #|  return query.captureQuantifiers[patternIndex][captureIndex];
  #|}

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
extern "js" fn ts_query_disable_capture(query : Query, name : String) =
  #|(query, name) => {
  #|  return query.disableCapture(name);
  #|}

///|
/// Disable a certain capture within a query.
///
/// This prevents the capture from being returned in matches, and also avoids
/// any resource usage associated with recording the capture. Currently, there
/// is no way to undo this.
pub fn Query::disable_capture(self : Query, name : @string.View) -> Unit {
  ts_query_disable_capture(self, name.to_string())
}

///|
extern "js" fn ts_query_disable_pattern(query : Query, pattern_index : UInt) =
  #|(query, patternIndex) => {
  #|  return query.disablePattern(patternIndex);
  #|}

///|
/// Disable a certain pattern within a query.
///
/// This prevents the pattern from matching and removes most of the overhead
/// associated with the pattern. Currently, there is no way to undo this.
pub fn Query::disable_pattern(self : Query, pattern_index : Int) -> Unit {
  ts_query_disable_pattern(self, int_to_uint(pattern_index))
}

///|
extern "js" fn ts_query_matches(
  query : Query,
  node : Node
) -> Array[TSQueryMatch] =
  #|(query, node) => {
  #|  return query.matches(node);
  #|}

///|
pub fn Query::matches(self : Query, node : Node) -> Array[QueryMatch] {
  let ts_matches = ts_query_matches(self, node)
  let matches = []
  for ts_match in ts_matches {
    let query_match = QueryMatch::{ query: self, query_match: ts_match }
    matches.push(query_match)
  }
  matches
}

///|
pub extern "js" fn Query::captures(
  self : Query,
  node : Node
) -> Array[QueryCapture] =
  #|(query, node) => {
  #|  return query.captures(node);
  #|}
