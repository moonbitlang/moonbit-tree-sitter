///|
type LookaheadIterator

///|
#borrow(iterator)
extern "c" fn ts_lookahead_iterator_is_null(
  iterator : LookaheadIterator,
) -> Bool = "moonbit_c_is_null"

///|
impl Nullable for LookaheadIterator with is_null(self : LookaheadIterator) -> Bool {
  ts_lookahead_iterator_is_null(self)
}

///|
extern "c" fn ts_lookahead_iterator_new(
  language : Language,
  state : StateId,
) -> LookaheadIterator = "moonbit_ts_lookahead_iterator_new"

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
  state : StateId,
) -> LookaheadIterator? {
  ts_lookahead_iterator_new(language, state).to_option()
}

///|
/// Reset the lookahead iterator to another state.
///
/// This returns `true` if the iterator was reset to the given state and `false`
/// otherwise.
#borrow(self)
pub extern "c" fn LookaheadIterator::reset_state(
  self : LookaheadIterator,
  state : StateId,
) -> Bool = "moonbit_ts_lookahead_iterator_reset_state"

///|
/// Reset the lookahead iterator.
///
/// This returns `true` if the language was set successfully and `false`
/// otherwise.
#borrow(self)
pub extern "c" fn LookaheadIterator::reset(
  self : LookaheadIterator,
  language : Language,
  state : StateId,
) -> Bool = "moonbit_ts_lookahead_iterator_reset"

///|
/// Get the current language of the lookahead iterator.
#borrow(self)
pub extern "c" fn LookaheadIterator::language(
  self : LookaheadIterator,
) -> Language = "moonbit_ts_lookahead_iterator_language"

///|
/// Advance the lookahead iterator to the next symbol.
///
/// This returns `true` if there is a new symbol and `false` otherwise.
#borrow(iterator)
pub extern "c" fn LookaheadIterator::next(iterator : LookaheadIterator) -> Bool = "moonbit_ts_lookahead_iterator_next"

///|
/// Get the current symbol of the lookahead iterator.
#borrow(self)
pub extern "c" fn LookaheadIterator::current_symbol(
  self : LookaheadIterator,
) -> Symbol = "moonbit_ts_lookahead_iterator_current_symbol"

///|
#borrow(iterator)
extern "c" fn ts_lookahead_iterator_current_symbol_name(
  iterator : LookaheadIterator,
) -> @native.ConstPtr[Byte] = "moonbit_ts_lookahead_iterator_current_symbol_name"

///|
/// Get the current symbol type of the lookahead iterator as a string.
pub fn LookaheadIterator::current_symbol_name(
  self : LookaheadIterator,
) -> String? {
  let bytes = ts_lookahead_iterator_current_symbol_name(self)
  decode_c_string(bytes)
}
