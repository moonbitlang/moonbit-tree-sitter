///|
struct InputEdit(FixedArray[UInt32])

///|
extern "js" fn ts_input_edit_new(
  start_byte : UInt32,
  old_end_byte : UInt32,
  new_end_byte : UInt32,
  start_point : Point,
  old_end_point : Point,
  new_end_point : Point,
) -> InputEdit =
  #|(start_byte, old_end_byte, new_end_byte, start_point, old_end_point, new_end_point) => {
  #|  return {
  #|    startPosition: start_point,
  #|    oldEndPosition: old_end_point,
  #|    newEndPosition: new_end_point,
  #|    startIndex: start_byte,
  #|    oldEndIndex: old_end_byte,
  #|    newEndIndex: new_end_byte,
  #|  }
  #|}

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
