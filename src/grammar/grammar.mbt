///|
#derive(Eq, Hash)
enum PrecType {
  NonAssoc
  Left
  Right
  Dynamic
}

///|
impl Show for PrecType with fn to_string(self) {
  match self {
    PrecType::NonAssoc => "PREC"
    PrecType::Left => "PREC_LEFT"
    PrecType::Right => "PREC_RIGHT"
    PrecType::Dynamic => "PREC_DYNAMIC"
  }
}

///|
impl Show for PrecType with fn output(self, logger) {
  logger.write_string(Show::to_string(self))
}

///|
impl ToJson for PrecType with fn to_json(self) {
  @json.to_json(Show::to_string(self))
}

///|
#derive(Debug, Hash, Eq)
enum PrecValue {
  Number(Int32)
  String(String)
}

///|
impl ToJson for PrecValue with fn to_json(self : PrecValue) -> Json {
  match self {
    PrecValue::Number(value) => @json.to_json(value)
    PrecValue::String(value) => @json.to_json(value)
  }
}

///|
impl @json.FromJson for PrecValue with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> PrecValue raise @json.JsonDecodeError {
  match json {
    Number(value, ..) => PrecValue::Number(value.to_int())
    String(value) => PrecValue::String(value)
    _ => {
      let message = "PrecValue::from_json: expected number or string, got \{Repr(json)}"
      raise @json.JsonDecodeError((json_path, message))
    }
  }
}

///|
#derive(Debug, Hash, Eq)
pub enum Rule {
  Alias(named~ : Bool, String, Rule)
  Blank
  Symbol(String)
  String(String)
  Repeat(Rule)
  Repeat1(Rule)
  Choice(Array[Rule])
  Seq(Array[Rule])
  Field(name~ : String, Rule)
  Token(immediate~ : Bool, Rule)
  Prec(prec~ : PrecType, value~ : PrecValue, Rule)
  Pattern(String)
}

///|
fn[E : Error] Rule::visit_rule(
  self : Rule,
  visitor : (Rule) -> Unit raise E,
) -> Unit raise E {
  visitor(self)
  match self {
    Alias(_, rule, ..) => rule.visit_rule(visitor)
    Prec(rule, ..) => rule.visit_rule(visitor)
    Token(rule, ..) => rule.visit_rule(visitor)
    Field(rule, ..) => rule.visit_rule(visitor)
    Seq(rules) | Choice(rules) =>
      for rule in rules {
        rule.visit_rule(visitor)
      }
    Repeat1(rule) | Repeat(rule) => rule.visit_rule(visitor)
    String(_) => ()
    Symbol(_) => ()
    Blank => ()
    Pattern(_) => ()
  }
}

///|
impl @json.FromJson for Rule with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Rule raise @json.JsonDecodeError {
  match json {
    {
      "type": "ALIAS",
      "named": True
      | False as named,
      "value": String(value),
      "content": rule,
      ..
    } =>
      Rule::Alias(
        named=@json.from_json(named),
        value,
        @json.FromJson::from_json(rule, json_path.add_key("content")),
      )
    { "type": "BLANK", .. } => Rule::Blank
    { "type": "SYMBOL", "name": String(name), .. } => Rule::Symbol(name)
    { "type": "STRING", "value": String(value), .. } => Rule::String(value)
    { "type": "CHOICE", "members": Array(members_json), .. } => {
      let members_json_path = json_path.add_key("members")
      let rules = []
      for i, member_json in members_json {
        rules.push(
          @json.FromJson::from_json(member_json, members_json_path.add_index(i)),
        )
      }
      Rule::Choice(rules)
    }
    { "type": "SEQ", "members": Array(members_json), .. } => {
      let members_json_path = json_path.add_key("members")
      let rules = []
      for i, member_json in members_json {
        rules.push(
          @json.FromJson::from_json(member_json, members_json_path.add_index(i)),
        )
      }
      Rule::Seq(rules)
    }
    { "type": "REPEAT", "content": rule, .. } =>
      Rule::Repeat(
        @json.FromJson::from_json(rule, json_path.add_key("content")),
      )
    { "type": "REPEAT1", "content": rule, .. } =>
      Rule::Repeat1(
        @json.FromJson::from_json(rule, json_path.add_key("content")),
      )
    { "type": "TOKEN", "content": rule, .. } =>
      Rule::Token(
        immediate=false,
        @json.FromJson::from_json(rule, json_path.add_key("content")),
      )
    { "type": "IMMEDIATE_TOKEN", "content": rule, .. } =>
      Rule::Token(
        immediate=true,
        @json.FromJson::from_json(rule, json_path.add_key("content")),
      )
    { "type": "FIELD", "name": String(name), "content": rule, .. } =>
      Rule::Field(
        name~,
        @json.FromJson::from_json(rule, json_path.add_key("content")),
      )
    {
      "type": String([.. "PREC", .. suffix]),
      "value": value,
      "content": rule,
      ..
    } => {
      let prec = match suffix {
        [.. ""] => PrecType::NonAssoc
        [.. "_LEFT"] => PrecType::Left
        [.. "_RIGHT"] => PrecType::Right
        [.. "_DYNAMIC"] => PrecType::Dynamic
        suffix => {
          let message = "Rule::from_json: invalid precedence type \"PREC\{suffix}\""
          raise @json.JsonDecodeError((json_path, message))
        }
      }
      Rule::Prec(
        prec~,
        value=value |> @json.from_json(path=json_path.add_key("value")),
        @json.FromJson::from_json(rule, json_path.add_key("content")),
      )
    }
    { "type": "PATTERN", "value": String(value), .. } => Rule::Pattern(value)
    { "type": String(type_), .. } => {
      let message = "Rule::from_json: unknown rule type \"\{Repr(type_)}\""
      raise @json.JsonDecodeError((json_path, message))
    }
    { "type": type_, .. } => {
      let message = "Rule::from_json: expected object with \"type\" field, got \{Repr(type_)}"
      raise @json.JsonDecodeError((json_path, message))
    }
    json => {
      let message = "Rule::from_json: expected object with \"type\" field, got \{Repr(json)}"
      raise @json.JsonDecodeError((json_path, message))
    }
  }
}

///|
impl ToJson for Rule with fn to_json(self : Rule) -> Json {
  match self {
    Alias(named~, value, rule) =>
      {
        "type": "ALIAS",
        "value": @json.to_json(value),
        "named": @json.to_json(named),
        "content": @json.to_json(rule),
      }
    Prec(prec~, value~, rule) =>
      {
        "type": @json.to_json(prec),
        "value": @json.to_json(value),
        "content": @json.to_json(rule),
      }
    Token(immediate~, rule) => {
      let token_type = if immediate { "IMMEDIATE_TOKEN" } else { "TOKEN" }
      { "type": @json.to_json(token_type), "content": @json.to_json(rule) }
    }
    Field(name~, rule) =>
      {
        "type": "FIELD",
        "name": Json::string(name),
        "content": @json.to_json(rule),
      }
    Seq(rules) => { "type": "SEQ", "members": @json.to_json(rules) }
    Choice(rules) => { "type": "CHOICE", "members": @json.to_json(rules) }
    Repeat1(rule) => { "type": "REPEAT1", "content": @json.to_json(rule) }
    Repeat(rule) => { "type": "REPEAT", "content": @json.to_json(rule) }
    String(value) => { "type": "STRING", "value": @json.to_json(value) }
    Symbol(name) => { "type": "SYMBOL", "name": @json.to_json(name) }
    Blank => { "type": "BLANK" }
    Pattern(value) => { "type": "PATTERN", "value": @json.to_json(value) }
  }
}

///|
#derive(Debug)
struct RuleName {
  name : String
  mut rule : Rule?
}

///|
impl @json.FromJson for RuleName with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> RuleName raise @json.JsonDecodeError {
  guard json is String(name) else {
    let message = "RuleName::from_json: expected string, got \{Repr(json)}"
    raise @json.JsonDecodeError((json_path, message))
  }
  { name, rule: None, }
}

///|
impl ToJson for RuleName with fn to_json(self : RuleName) -> Json {
  @json.to_json(self.name)
}

///|
#derive(Debug)
pub struct Grammar {
  schema : String
  name : String
  rules : Map[String, Rule]
  extras : Array[Rule]
  supertypes : Array[RuleName]
  reserved : Map[String, Rule]
  precedences : Array[Array[Rule]]
  externals : Array[Rule]
  inline : Array[RuleName]
  conflicts : Array[Array[RuleName]]
  word : RuleName?
}

///|
pub impl @json.FromJson for Grammar with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Grammar raise @json.JsonDecodeError {
  match json {
    Object(
      {
        "$schema": String(schema),
        "name": String(name),
        "rules": Object(rules_json),
        "extras": Array(extras_json),
        "supertypes": Array(supertypes_json),
        "reserved": Object(reserved_json),
        "precedences": Array(precedences),
        "externals": Array(externals),
        "inline": Array(inline),
        "conflicts": Array(conflicts),
        ..
      } as json,
    ) => {
      let word = match json.get("word") {
        None => None
        Some(Null) => None
        Some(String(name)) =>
          Some(
            @json.FromJson::from_json(
              @json.to_json(name),
              json_path.add_key("word"),
            ),
          )
        _ => {
          let message = "Grammar::from_json: expected string or null for \"word\""
          raise @json.JsonDecodeError((json_path.add_key("word"), message))
        }
      }
      Grammar::{
        schema,
        name,
        rules: {
          let rules = {}
          for name, rule_json in rules_json {
            rules[name] = @json.FromJson::from_json(
              rule_json,
              json_path.add_key("rules").add_key(name),
            )
          }
          rules
        },
        extras: extras_json.map(rule_json => {
          @json.FromJson::from_json(rule_json, json_path.add_key("extras"))
        }),
        supertypes: supertypes_json.map(rule_name_json => {
          @json.FromJson::from_json(
            rule_name_json,
            json_path.add_key("supertypes"),
          )
        }),
        reserved: {
          let reserved = {}
          for name, rule_json in reserved_json {
            reserved[name] = @json.FromJson::from_json(
              rule_json,
              json_path.add_key("reserved").add_key(name),
            )
          }
          reserved
        },
        precedences: precedences.map(rules_json => {
          @json.from_json(rules_json, path=json_path.add_key("precedences"))
        }),
        externals: externals.map(rule_json => {
          @json.from_json(rule_json, path=json_path.add_key("externals"))
        }),
        inline: inline.map(rule_name_json => {
          @json.from_json(rule_name_json, path=json_path.add_key("inline"))
        }),
        conflicts: conflicts.map(rule_names_json => {
          @json.from_json(rule_names_json, path=json_path.add_key("conflicts"))
        }),
        word,
      }
    }
    _ => {
      let message = "Grammar::from_json: expected object with required fields"
      raise @json.JsonDecodeError((json_path, message))
    }
  }
}

///|
pub impl ToJson for Grammar with fn to_json(self : Grammar) -> Json {
  {
    "$schema": @json.to_json(self.schema),
    "name": @json.to_json(self.name),
    "rules": @json.to_json(self.rules),
    "extras": @json.to_json(self.extras),
    "supertypes": @json.to_json(self.supertypes),
    "reserved": @json.to_json(self.reserved),
    "precedences": @json.to_json(self.precedences),
    "externals": @json.to_json(self.externals),
    "inline": @json.to_json(self.inline),
    "conflicts": @json.to_json(self.conflicts),
    "word": match self.word {
      None => Json::null()
      Some(word) => @json.to_json(word)
    },
  }
}

///|
#derive(Debug)
suberror GrammarParseError {
  JsonDecodeError(@json.JsonDecodeError)
  RuleNotFound(String)
}

///|
pub fn Grammar::from_json(json : Json) -> Grammar raise GrammarParseError {
  let grammar : Grammar = @json.from_json(json) catch {
    error => raise JsonDecodeError(error)
  }
  for _, rule in grammar.rules {
    let visitor = fn(rule : Rule) -> Unit raise GrammarParseError {
      match rule {
        Symbol(name) =>
          if grammar.rules.get(name) is None {
            raise RuleNotFound(name)
          }
        _ => return
      }
    }
    rule.visit_rule(visitor)
  }
  for supertype in grammar.supertypes {
    guard grammar.rules.get(supertype.name) is Some(rule) else {
      raise RuleNotFound(supertype.name)
    }
    supertype.rule = Some(rule)
  }
  for inline in grammar.inline {
    guard grammar.rules.get(inline.name) is Some(rule) else {
      raise RuleNotFound(inline.name)
    }
    inline.rule = Some(rule)
  }
  for conflict in grammar.conflicts {
    for rule_name in conflict {
      guard grammar.rules.get(rule_name.name) is Some(rule) else {
        raise RuleNotFound(rule_name.name)
      }
      rule_name.rule = Some(rule)
    }
  }
  if grammar.word is Some(word) {
    guard grammar.rules.get(word.name) is Some(rule) else {
      raise RuleNotFound(word.name)
    }
    word.rule = Some(rule)
  }
  grammar
}

///|
pub impl Debug for PrecType with fn to_repr(self) {
  Repr::literal(Show::to_string(self))
}

///|
pub impl Show for PrecValue with fn output(self, logger) {
  logger.write_string(@debug.to_string(self))
}

///|
pub impl Show for Rule with fn output(self, logger) {
  logger.write_string(@debug.to_string(self))
}

///|
pub impl Show for RuleName with fn output(self, logger) {
  logger.write_string(@debug.to_string(self))
}

///|
pub impl Show for Grammar with fn output(self, logger) {
  logger.write_string(@debug.to_string(self))
}

///|
pub impl Show for GrammarParseError with fn output(self, logger) {
  logger.write_string(@debug.to_string(self))
}
