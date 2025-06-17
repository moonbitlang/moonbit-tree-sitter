///|
type Range FixedArray[UInt]

///|
pub impl Show for Range with output(self : Range, logger : &@builtin.Logger) -> Unit {
  logger.write_object(self.start_point())
  logger.write_string(" - ")
  logger.write_object(self.end_point())
}

///|
fn ts_range_new(
  start_point : Point,
  end_point : Point,
  start_byte : UInt,
  end_byte : UInt
) -> Range {
  [
    ts_point_row(start_point),
    ts_point_column(start_point),
    ts_point_row(end_point),
    ts_point_column(end_point),
    start_byte,
    end_byte,
  ]
}

///|
pub fn Range::new(
  start_point : Point,
  end_point : Point,
  start_byte : Int,
  end_byte : Int
) -> Range {
  let start_byte = int_to_uint(start_byte)
  let end_byte = int_to_uint(end_byte)
  ts_range_new(start_point, end_point, start_byte, end_byte)
}

///|
pub fn Range::start_point(self : Range) -> Point {
  ts_point_new(self.inner()[0], self.inner()[1])
}

///|
pub fn Range::end_point(self : Range) -> Point {
  ts_point_new(self.inner()[2], self.inner()[3])
}

///|
fn ts_range_start_byte(point : Range) -> UInt {
  point.inner()[4]
}

///|
pub fn Range::start_byte(self : Range) -> Int {
  uint_to_int(ts_range_start_byte(self))
}

///|
fn ts_range_end_byte(point : Range) -> UInt {
  point.inner()[5]
}

///|
pub fn Range::end_byte(self : Range) -> Int {
  uint_to_int(ts_range_end_byte(self))
}
