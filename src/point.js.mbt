///|
type Point

///|
pub impl Show for Point with output(self : Point, logger : &@builtin.Logger) -> Unit {
  logger.write_string("(")
  logger.write_string(self.row().to_string())
  logger.write_string(", ")
  logger.write_string(self.column().to_string())
  logger.write_string(")")
}

///|
impl ToJson for Point with to_json(self : Point) -> Json {
  { "row": self.row().to_json(), "column": self.column().to_json() }
}

///|
extern "js" fn ts_point_new(row : UInt, column : UInt) -> Point =
  #|(row, column) => {
  #|  return { row: row, column: column };
  #|}

///|
pub fn Point::new(row : Int, column : Int) -> Point {
  ts_point_new(int_to_uint(row), int_to_uint(column))
}

///|
extern "js" fn ts_point_row(point : Point) -> UInt =
  #|(point) => {
  #|  return point.row;
  #|}

///|
pub fn Point::row(self : Point) -> Int {
  uint_to_int(ts_point_row(self))
}

///|
extern "js" fn ts_point_column(point : Point) -> UInt =
  #|(point) => {
  #|  return point.column;
  #|}

///|
pub fn Point::column(self : Point) -> Int {
  uint_to_int(ts_point_column(self))
}
