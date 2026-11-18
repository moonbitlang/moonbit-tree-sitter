///|
struct Point(FixedArray[UInt32])

///|
pub impl Show for Point with fn output(self : Point, logger : &@builtin.Logger) -> Unit {
  logger.write_string("(")
  logger.write_string(self.row().to_string())
  logger.write_string(", ")
  logger.write_string(self.column().to_string())
  logger.write_string(")")
}

///|
impl ToJson for Point with fn to_json(self : Point) -> Json {
  { "row": @json.to_json(self.row()), "column": @json.to_json(self.column()) }
}

///|
fn ts_point_new(row : UInt32, column : UInt32) -> Point {
  [row, column]
}

///|
pub fn Point::new(row : Int32, column : Int32) -> Point {
  ts_point_new(int_to_uint(row), int_to_uint(column))
}

///|
fn ts_point_row(point : Point) -> UInt32 {
  point.0[0]
}

///|
pub fn Point::row(self : Point) -> Int32 {
  uint_to_int(ts_point_row(self))
}

///|
fn ts_point_column(point : Point) -> UInt32 {
  point.0[1]
}

///|
pub fn Point::column(self : Point) -> Int32 {
  uint_to_int(ts_point_column(self))
}

///|
pub impl Debug for Point with fn to_repr(self) {
  Repr::literal(Show::to_string(self))
}
