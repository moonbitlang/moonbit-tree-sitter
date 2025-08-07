///|
enum PrecType {
  NonAssoc
  Left
  Right
  Dynamic
} derive(Eq, Hash)

///|
impl Show for PrecType with to_string(self) {
  match self {
    PrecType::NonAssoc => "PREC"
    PrecType::Left => "PREC_LEFT"
    PrecType::Right => "PREC_RIGHT"
    PrecType::Dynamic => "PREC_DYNAMIC"
  }
}

///|
impl Show for PrecType with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
impl ToJson for PrecType with to_json(self) {
  self.to_string().to_json()
}

///|
enum PrecValue {
  Number(Int)
  String(String)
} derive(Show, Hash, Eq)

///|
impl ToJson for PrecValue with to_json(self : PrecValue) -> Json {
  match self {
    PrecValue::Number(value) => value.to_json()
    PrecValue::String(value) => value.to_json()
  }
}

///|
impl @json.FromJson for PrecValue with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> PrecValue raise @json.JsonDecodeError {
  match json {
    Number(value, ..) => PrecValue::Number(value.to_int())
    String(value) => PrecValue::String(value)
    _ => {
      let message = "PrecValue::from_json: expected number or string, got \{json}"
      raise @json.JsonDecodeError((json_path, message))
    }
  }
}

///|
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
} derive(Show, Hash, Eq)

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
impl @json.FromJson for Rule with from_json(
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
        Rule::from_json(rule, json_path.add_key("content")),
      )
    { "type": "BLANK", .. } => Rule::Blank
    { "type": "SYMBOL", "name": String(name), .. } => Rule::Symbol(name)
    { "type": "STRING", "value": String(value), .. } => Rule::String(value)
    { "type": "CHOICE", "members": Array(members_json), .. } => {
      let members_json_path = json_path.add_key("members")
      let rules = []
      for i, member_json in members_json {
        rules.push(Rule::from_json(member_json, members_json_path.add_index(i)))
      }
      Rule::Choice(rules)
    }
    { "type": "SEQ", "members": Array(members_json), .. } => {
      let members_json_path = json_path.add_key("members")
      let rules = []
      for i, member_json in members_json {
        rules.push(Rule::from_json(member_json, members_json_path.add_index(i)))
      }
      Rule::Seq(rules)
    }
    { "type": "REPEAT", "content": rule, .. } =>
      Rule::Repeat(Rule::from_json(rule, json_path.add_key("content")))
    { "type": "REPEAT1", "content": rule, .. } =>
      Rule::Repeat1(Rule::from_json(rule, json_path.add_key("content")))
    { "type": "TOKEN", "content": rule, .. } =>
      Rule::Token(
        immediate=false,
        Rule::from_json(rule, json_path.add_key("content")),
      )
    { "type": "IMMEDIATE_TOKEN", "content": rule, .. } =>
      Rule::Token(
        immediate=true,
        Rule::from_json(rule, json_path.add_key("content")),
      )
    { "type": "FIELD", "name": String(name), "content": rule, .. } =>
      Rule::Field(name~, Rule::from_json(rule, json_path.add_key("content")))
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
        Rule::from_json(rule, json_path.add_key("content")),
      )
    }
    { "type": "PATTERN", "value": String(value), .. } => Rule::Pattern(value)
    { "type": String(type_), .. } => {
      let message = "Rule::from_json: unknown rule type \"\{type_}\""
      raise @json.JsonDecodeError((json_path, message))
    }
    { "type": type_, .. } => {
      let message = "Rule::from_json: expected object with \"type\" field, got \{type_}"
      raise @json.JsonDecodeError((json_path, message))
    }
    json => {
      let message = "Rule::from_json: expected object with \"type\" field, got \{json}"
      raise @json.JsonDecodeError((json_path, message))
    }
  }
}

///|
impl ToJson for Rule with to_json(self : Rule) -> Json {
  match self {
    Alias(named~, value, rule) =>
      {
        "type": "ALIAS",
        "value": value.to_json(),
        "named": named.to_json(),
        "content": rule.to_json(),
      }
    Prec(prec~, value~, rule) =>
      {
        "type": prec.to_json(),
        "value": value.to_json(),
        "content": rule.to_json(),
      }
    Token(immediate~, rule) => {
      let token_type = if immediate { "IMMEDIATE_TOKEN" } else { "TOKEN" }
      { "type": token_type.to_json(), "content": rule.to_json() }
    }
    Field(name~, rule) =>
      { "type": "FIELD", "name": Json::string(name), "content": rule.to_json() }
    Seq(rules) => { "type": "SEQ", "members": rules.to_json() }
    Choice(rules) => { "type": "CHOICE", "members": rules.to_json() }
    Repeat1(rule) => { "type": "REPEAT1", "content": rule.to_json() }
    Repeat(rule) => { "type": "REPEAT", "content": rule.to_json() }
    String(value) => { "type": "STRING", "value": value.to_json() }
    Symbol(name) => { "type": "SYMBOL", "name": name.to_json() }
    Blank => { "type": "BLANK" }
    Pattern(value) => { "type": "PATTERN", "value": value.to_json() }
  }
}

///|
struct RuleName {
  name : String
  mut rule : Rule?
} derive(Show)

///|
impl @json.FromJson for RuleName with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> RuleName raise @json.JsonDecodeError {
  guard json is String(name) else {
    let message = "RuleName::from_json: expected string, got \{json}"
    raise @json.JsonDecodeError((json_path, message))
  }
  { name, rule: None }
}

///|
impl ToJson for RuleName with to_json(self : RuleName) -> Json {
  self.name.to_json()
}

///|
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
} derive(Show)

///|
pub impl @json.FromJson for Grammar with from_json(
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
      } as json
    ) => {
      let word = match json.get("word") {
        None => None
        Some(Null) => None
        Some(String(name)) =>
          Some(RuleName::from_json(name.to_json(), json_path.add_key("word")))
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
            rules[name] = Rule::from_json(
              rule_json,
              json_path.add_key("rules").add_key(name),
            )
          }
          rules
        },
        extras: extras_json.map(rule_json => Rule::from_json(
          rule_json,
          json_path.add_key("extras"),
        )),
        supertypes: supertypes_json.map(rule_name_json => RuleName::from_json(
          rule_name_json,
          json_path.add_key("supertypes"),
        )),
        reserved: {
          let reserved = {}
          for name, rule_json in reserved_json {
            reserved[name] = Rule::from_json(
              rule_json,
              json_path.add_key("reserved").add_key(name),
            )
          }
          reserved
        },
        precedences: precedences.map(rules_json => @json.from_json(
          rules_json,
          path=json_path.add_key("precedences"),
        )),
        externals: externals.map(rule_json => @json.from_json(
          rule_json,
          path=json_path.add_key("externals"),
        )),
        inline: inline.map(rule_name_json => @json.from_json(
          rule_name_json,
          path=json_path.add_key("inline"),
        )),
        conflicts: conflicts.map(rule_names_json => @json.from_json(
          rule_names_json,
          path=json_path.add_key("conflicts"),
        )),
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
pub impl ToJson for Grammar with to_json(self : Grammar) -> Json {
  {
    "$schema": self.schema.to_json(),
    "name": self.name.to_json(),
    "rules": self.rules.to_json(),
    "extras": self.extras.to_json(),
    "supertypes": self.supertypes.to_json(),
    "reserved": self.reserved.to_json(),
    "precedences": self.precedences.to_json(),
    "externals": self.externals.to_json(),
    "inline": self.inline.to_json(),
    "conflicts": self.conflicts.to_json(),
    "word": match self.word {
      None => Null
      Some(word) => word.to_json()
    },
  }
}

///|
suberror GrammarParseError {
  JsonDecodeError(@json.JsonDecodeError)
  RuleNotFound(String)
} derive(Show)

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
