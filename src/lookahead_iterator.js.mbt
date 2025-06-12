///|
type LookaheadIterator

///|
extern "js" fn ts_lookahead_iterator_is_null(
  iterator : LookaheadIterator
) -> Bool =
  #|(iterator) => {
  #|  return iterator === null || iterator === undefined;
  #|}

///|
impl Nullable for LookaheadIterator with is_null(self : LookaheadIterator) -> Bool {
  ts_lookahead_iterator_is_null(self)
}

///|
extern "js" fn ts_lookahead_iterator_new(
  language : Language,
  state : StateId
) -> LookaheadIterator =
  #|(language, state) => {
  #|  return language.lookaheadIterator(state);
  #|}

///|
/// Create a new lookahead iterator for the given language and parse state.
///
/// This returns `None` if state is invalid for the language.
///
/// Repeatedly using `LookaheadIterator::next` and
/// `LookaheadIterator::current_symbol` will generate valid symbols in the
/// given parse state. Newly created lookahead iterators will contain the
/// `ERROR` symbol.
///
/// Lookahead iterators can be useful to generate suggestions and improve syntax
/// error diagnostics. To get symbols valid in an ERROR node, use the lookahead
/// iterator on its first leaf node state. For `MISSING` nodes, a lookahead
/// iterator created on the previous non-extra leaf node may be appropriate.
pub fn LookaheadIterator::new(
  language : Language,
  state : StateId
) -> LookaheadIterator? {
  ts_lookahead_iterator_new(language, state).to_option()
}

///|
/// Reset the lookahead iterator to another state.
///
/// This returns `true` if the iterator was reset to the given state and `false`
/// otherwise.
pub extern "js" fn LookaheadIterator::reset_state(
  self : LookaheadIterator,
  state : StateId
) -> Bool =
  #|(self, state) => {
  #|  return self.resetState(state);
  #|}

///|
/// Reset the lookahead iterator.
///
/// This returns `true` if the language was set successfully and `false`
/// otherwise.
pub extern "js" fn LookaheadIterator::reset(
  self : LookaheadIterator,
  language : Language,
  state : StateId
) -> Bool =
  #|(self, language, state) => {
  #|  return self.reset(language, state);
  #|}

///|
/// Get the current symbol of the lookahead iterator.
pub extern "js" fn LookaheadIterator::current_symbol(
  self : LookaheadIterator
) -> Symbol =
  #|(self) => {
  #|  return self.currentTypeId;
  #|}

///|
extern "js" fn ts_lookahead_iterator_current_symbol_name(
  iterator : LookaheadIterator
) -> String =
  #|(iterator) => {
  #|  return iterator.currentType;
  #|}

///|
/// Get the current symbol type of the lookahead iterator as a string.
pub fn LookaheadIterator::current_symbol_name(
  self : LookaheadIterator
) -> @string.View? {
  let bytes = ts_lookahead_iterator_current_symbol_name(self).to_option()
  if bytes is Some(bytes) {
    Some(bytes)
  } else {
    None
  }
}

///|
/// true <=> IterContinue
/// false <=> IterEnd
extern "js" fn ts_lookahead_iterator_symbol_names(
  iterator : LookaheadIterator,
  f : (String) -> Bool
) -> Bool =
  #|(self, f) => {
  #|  for (const name of self) {
  #|    if (!f(name)) {
  #|      return false;
  #|    } else {
  #|      continue;
  #|    }
  #|  }
  #|  return true;
  #|}

///|
pub fn LookaheadIterator::symbol_names(
  self : LookaheadIterator
) -> Iter[String] {
  Iter::new(fn(yield_) {
    if ts_lookahead_iterator_symbol_names(self, fn(name) {
        match yield_(name) {
          IterContinue => true
          IterEnd => false
        }
      }) {
      IterContinue
    } else {
      IterEnd
    }
  })
}
