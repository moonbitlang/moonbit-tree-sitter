///|
struct Input[DecodeFunction] {
  read : (UInt, Point) -> @bytes.View
  decode : DecodeFunction
}

///|
pub fn[DecodeFunction : DecodeFunction] Input::new(
  read : (Int, Point) -> @bytes.View,
  decode : DecodeFunction
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
type InputEdit FixedArray[UInt]

///|
fn ts_input_edit_new(
  start_byte : UInt,
  old_end_byte : UInt,
  new_end_byte : UInt,
  start_point : Point,
  old_end_point : Point,
  new_end_point : Point
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
  start_byte~ : Int,
  old_end_byte~ : Int,
  new_end_byte~ : Int,
  start_point~ : Point,
  old_end_point~ : Point,
  new_end_point~ : Point
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
  bytes_read : Int
}

///|
pub fn DecodeResult::new(code_point~ : Char, bytes_read~ : Int) -> DecodeResult {
  { code_point, bytes_read }
}

///|
/// This function signature reads one code point from the given bytes,
/// returning the number of bytes consumed and the code point.
/// If the input is invalid, return `None`.
pub(open) trait DecodeFunction {
  encoding(Self) -> InputEncoding = _
  decode(@bytes.View) -> DecodeResult?
}

///|
impl DecodeFunction with encoding(self) -> InputEncoding {
  ignore(self)
  Custom
}

///|
enum InputEncoding {
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
pub impl DecodeFunction for @encoding.Encoding with encoding(self) -> InputEncoding {
  match self {
    @encoding.UTF8 => UTF8
    @encoding.UTF16LE => UTF16LE
    @encoding.UTF16BE => UTF16BE
  }
}

///|
pub impl DecodeFunction for @encoding.Encoding with decode(bytes) -> DecodeResult? {
  ignore(bytes)
  None
}

///|
fn InputEncoding::to_uint(self : InputEncoding) -> UInt {
  match self {
    UTF8 => 0
    UTF16LE => 1
    UTF16BE => 2
    Custom => 3
  }
}
