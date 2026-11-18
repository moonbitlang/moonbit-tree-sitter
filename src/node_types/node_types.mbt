///|
#derive(ToJson, Debug)
pub struct ChildType {
  multiple : Bool
  required : Bool
  types : Array[NodeType]
}

///|
impl @json.FromJson for ChildType with fn from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChildType raise @json.JsonDecodeError {
  match json {
    {
      "multiple": True
      | False as multiple,
      "required": True
      | False as required,
      "types": types,
      ..
    } =>
      ChildType::{
        multiple: @json.from_json(multiple, path=path.add_key("multiple")),
        required: @json.from_json(required, path=path.add_key("required")),
        types: @json.from_json(types, path=path.add_key("types")),
      }
    json =>
      raise @json.JsonDecodeError((path, "Invalid child type: \{Repr(json)}"))
  }
}

///|
#derive(Debug)
pub enum NodeTypePayload {
  Empty
  Supertype(subtypes~ : Array[NodeType])
  Normal(fields~ : Map[String, ChildType], children~ : ChildType)
}

///|
#derive(Debug)
pub struct NodeType {
  type_ : String
  named : Bool
  payload : NodeTypePayload
}

///|
pub impl @json.FromJson for NodeType with fn from_json(
  json : Json,
  path : @json.JsonPath,
) -> NodeType raise @json.JsonDecodeError {
  match json {
    {
      "type": String(type_),
      "named": True
      | False as named,
      "subtypes": subtypes,
      ..
    } =>
      NodeType::{
        type_,
        named: @json.from_json(named, path=path.add_key("named")),
        payload: NodeTypePayload::Supertype(
          subtypes=@json.from_json(subtypes, path=path.add_key("subtypes")),
        ),
      }
    {
      "type": String(type_),
      "named": True
      | False as named,
      "fields": fields,
      "children": children,
      ..
    } =>
      NodeType::{
        type_,
        named: @json.from_json(named, path=path.add_key("named")),
        payload: NodeTypePayload::Normal(
          fields=@json.from_json(fields, path=path.add_key("fields")),
          children=@json.from_json(children, path=path.add_key("children")),
        ),
      }
    { "type": String(type_), "named": True | False as named, .. } =>
      NodeType::{
        type_,
        named: @json.from_json(named, path=path.add_key("named")),
        payload: NodeTypePayload::Empty,
      }
    json =>
      raise @json.JsonDecodeError((path, "Invalid node type: \{Repr(json)}"))
  }
}

///|
pub impl ToJson for NodeType with fn to_json(self : NodeType) -> Json {
  let type_ = @json.to_json(self.type_)
  let named = @json.to_json(self.named)
  match self.payload {
    Supertype(subtypes~) => {
      let subtypes = @json.to_json(subtypes)
      { "type": type_, "named": named, "subtypes": subtypes }
    }
    Empty => { "type": type_, "named": named }
    Normal(fields~, children~) => {
      let fields = @json.to_json(fields)
      let children = @json.to_json(children)
      { "type": type_, "named": named, "fields": fields, "children": children }
    }
  }
}

///|
#derive(@json.FromJson, ToJson, Debug)
pub struct NodeTypes(Array[NodeType])

///|
pub fn NodeTypes::from_json(
  json : Json,
) -> NodeTypes raise @json.JsonDecodeError {
  @json.from_json(json)
}

///|
pub impl Show for ChildType with fn output(self, logger) {
  logger.write_string(@debug.to_string(self))
}

///|
pub impl Show for NodeTypePayload with fn output(self, logger) {
  logger.write_string(@debug.to_string(self))
}

///|
pub impl Show for NodeType with fn output(self, logger) {
  logger.write_string(@debug.to_string(self))
}

///|
pub impl Show for NodeTypes with fn output(self, logger) {
  logger.write_string(@debug.to_string(self))
}
