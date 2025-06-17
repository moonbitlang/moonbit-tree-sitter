///|
pub struct ChildType {
  multiple : Bool
  required : Bool
  types : Array[NodeType]
} derive(ToJson, Show)

///|
impl @json.FromJson for ChildType with from_json(
  json : Json,
  path : @json.JsonPath
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
    json => raise @json.JsonDecodeError((path, "Invalid child type: \{json}"))
  }
}

///|
pub enum NodeTypePayload {
  Empty
  Supertype(subtypes~ : Array[NodeType])
  Normal(fields~ : Map[String, ChildType], children~ : ChildType)
} derive(Show)

///|
pub struct NodeType {
  type_ : String
  named : Bool
  payload : NodeTypePayload
} derive(Show)

///|
pub impl @json.FromJson for NodeType with from_json(
  json : Json,
  path : @json.JsonPath
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
    json => raise @json.JsonDecodeError((path, "Invalid node type: \{json}"))
  }
}

///|
pub impl ToJson for NodeType with to_json(self : NodeType) -> Json {
  let type_ = self.type_.to_json()
  let named = self.named.to_json()
  match self.payload {
    Supertype(subtypes~) => {
      let subtypes = subtypes.to_json()
      { "type": type_, "named": named, "subtypes": subtypes }
    }
    Empty => { "type": type_, "named": named }
    Normal(fields~, children~) => {
      let fields = fields.to_json()
      let children = children.to_json()
      { "type": type_, "named": named, "fields": fields, "children": children }
    }
  }
}

///|
pub type NodeTypes Array[NodeType] derive(@json.FromJson, ToJson, Show)

///|
pub fn NodeTypes::from_json(
  json : Json
) -> NodeTypes raise @json.JsonDecodeError {
  @json.from_json(json)
}
