///|
struct Input[DecodeFunction] {
  read : (UInt32, Point) -> BytesView
  decode : DecodeFunction
}

///|
pub fn[DecodeFunction] Input::new(
  read : (Int32, Point) -> BytesView,
  decode : DecodeFunction,
) -> Input[DecodeFunction] {
  {
    read: fn(byte, point) {
      let byte = uint_to_int(byte)
      read(byte, point)
    },
    decode,
  }
}

///|
struct InputEdit(FixedArray[UInt32])

///|
fn ts_input_edit_new(
  start_byte : UInt32,
  old_end_byte : UInt32,
  new_end_byte : UInt32,
  start_point : Point,
  old_end_point : Point,
  new_end_point : Point,
) -> InputEdit {
  [
    start_byte,
    old_end_byte,
    new_end_byte,
    ts_point_row(start_point),
    ts_point_column(start_point),
    ts_point_row(old_end_point),
    ts_point_column(old_end_point),
    ts_point_row(new_end_point),
    ts_point_column(new_end_point),
  ]
}

///|
pub fn InputEdit::new(
  start_byte~ : Int32,
  old_end_byte~ : Int32,
  new_end_byte~ : Int32,
  start_point~ : Point,
  old_end_point~ : Point,
  new_end_point~ : Point,
) -> InputEdit {
  let start_byte = int_to_uint(start_byte)
  let old_end_byte = int_to_uint(old_end_byte)
  let new_end_byte = int_to_uint(new_end_byte)
  ts_input_edit_new(
    start_byte, old_end_byte, new_end_byte, start_point, old_end_point, new_end_point,
  )
}

///|
struct DecodeResult {
  code_point : Char
  bytes_read : Int32
}

///|
pub fn DecodeResult::new(
  code_point~ : Char,
  bytes_read~ : Int32,
) -> DecodeResult {
  { code_point, bytes_read, }
}

///|
/// This function signature reads one code point from the given bytes,
/// returning the number of bytes consumed and the code point.
/// If the input is invalid, return `None`.
pub(open) trait DecodeFunction {
  fn encoding(Self) -> InputEncoding = _
  fn decode(BytesView) -> DecodeResult?
}

///|
impl DecodeFunction with fn encoding(self) -> InputEncoding {
  ignore(self)
  Custom
}

///|
pub(all) enum InputEncoding {
  UTF8
  UTF16LE
  UTF16BE
  Custom
}

///|
pub fn InputEncoding::custom() -> InputEncoding {
  Custom
}

///|
pub impl DecodeFunction for InputEncoding with fn encoding(self) -> InputEncoding {
  self
}

///|
pub impl DecodeFunction for InputEncoding with fn decode(_bytes) -> DecodeResult? {
  None
}

///|
fn InputEncoding::to_uint(self : InputEncoding) -> UInt32 {
  match self {
    UTF8 => 0
    UTF16LE => 1
    UTF16BE => 2
    Custom => 3
  }
}
