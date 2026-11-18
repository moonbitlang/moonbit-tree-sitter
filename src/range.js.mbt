///|
type Range

///|
pub impl Show for Range with fn output(self : Range, logger : &@builtin.Logger) -> Unit {
  logger.write_object(self.start_point())
  logger.write_string(" - ")
  logger.write_object(self.end_point())
}

///|
extern "js" fn ts_range_new(
  start_point : Point,
  end_point : Point,
  start_byte : UInt32,
  end_byte : UInt32,
) -> Range =
  #|(start_point, end_point, start_byte, end_byte) => {
  #|  return {
  #|    startPosition: start_point,
  #|    endPosition: end_point,
  #|    startIndex: start_byte,
  #|    endIndex: end_byte,
  #|  }
  #|}

///|
pub fn Range::new(
  start_pointer : Point,
  end_pointer : Point,
  start_byte : Int32,
  end_byte : Int32,
) -> Range {
  let start_byte = int_to_uint(start_byte)
  let end_byte = int_to_uint(end_byte)
  ts_range_new(start_pointer, end_pointer, start_byte, end_byte)
}

///|
pub extern "js" fn Range::start_point(self : Range) -> Point =
  #|(range) => {
  #|  return range.startPosition;
  #|}

///|
pub extern "js" fn Range::end_point(self : Range) -> Point =
  #|(range) => {
  #|  return range.endPosition;
  #|}

///|
pub extern "js" fn Range::start_byte(self : Range) -> Int32 =
  #|(range) => {
  #|  return range.startIndex;
  #|}

///|
pub extern "js" fn Range::end_byte(self : Range) -> Int32 =
  #|(range) => {
  #|  return range.endIndex;
  #|}

///|
pub impl Debug for Range with fn to_repr(self) {
  Repr::literal(Show::to_string(self))
}
