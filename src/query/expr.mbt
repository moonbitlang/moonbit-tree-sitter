///|
enum Node {
  True
  False
  And(Node, Node)
  Or(Node, Node)
  Not(Node)
  Type(String)
  Child(Expr)
  Descendant(Expr)
} derive(Eq)

///|
impl ToJson for Node with to_json(self : Node) -> Json {
  match self {
    True => Json::boolean(true)
    False => Json::boolean(false)
    And(n1, n2) => { "and": [n1, n2] }
    Or(n1, n2) => { "or": [n1, n2] }
    Not(n1) => { "not": n1 }
    Type(t) => t.to_json()
    Child(e) => { "child": e.to_json() }
    Descendant(e) => { "descendant": e.to_json() }
  }
}

///|
impl Show for Node with output(self : Node, logger : &Logger) -> Unit {
  match self {
    True => logger.write_string("true")
    False => logger.write_string("false")
    And(n1, n2) => {
      logger.write_char('(')
      n1.output(logger)
      logger.write_string(" && ")
      n2.output(logger)
      logger.write_char(')')
    }
    Or(n1, n2) => {
      logger.write_char('(')
      n1.output(logger)
      logger.write_string(" || ")
      n2.output(logger)
      logger.write_char(')')
    }
    Not(n1) => {
      logger.write_string("!(")
      n1.output(logger)
      logger.write_char(')')
    }
    Type(t) => logger.write_string(t.escape())
    Child(e) => {
      logger.write_string(".(")
      e.output(logger)
      logger.write_char(')')
    }
    Descendant(e) => {
      logger.write_string("..(")
      e.output(logger)
      logger.write_char(')')
    }
  }
}

///|
pub fn Node::and_(self : Node, other : Node) -> Node {
  match (self, other) {
    (True, other) => other
    (other, True) => other
    (False, _) => False
    (_, False) => False
    (And(n1, n2), n3) => n1.and_(n2.and_(n3))
    (Or(n1, n2), n3) => n1.and_(n3).or_(n2.and_(n3))
    (n1, Or(n2, n3)) => n1.and_(n2).or_(n1.and_(n3))
    (Not(n1), n2) | (n1, Not(n2)) if n1 == n2 => False
    (Child(e1), Child(e2)) => Child(e1.and_(e2))
    (n1, n2) => And(n1, n2)
  }
}

///|
pub fn Node::or_(self : Node, other : Node) -> Node {
  match (self, other) {
    (True, _) => True
    (_, True) => True
    (False, other) => other
    (other, False) => other
    (Or(n1, n2), n3) => n1.or_(n2.or_(n3))
    (Not(n1), n2) | (n1, Not(n2)) if n1 == n2 => True
    (Child(e1), Child(e2)) => Child(e1.alt(e2))
    (n1, n2) => Or(n1, n2)
  }
}

///|
pub fn Node::not(self : Node) -> Node {
  match self {
    True => False
    False => True
    And(n1, n2) => n1.not().or_(n2.not())
    Or(n1, n2) => n1.not().and_(n2.not())
    Not(n1) => n1
    n1 => Not(n1)
  }
}

///|
pub fn Node::type_(t : String) -> Node {
  Type(t)
}

///|
pub fn Node::truthy() -> Node {
  True
}

///|
pub fn Node::falsy() -> Node {
  False
}

///|
test {
  let a = Node::type_("a")
  let b = Node::type_("b")
  let c = Node::type_("c")
  let d = Node::type_("d")
  let e = Node::type_("e")
  let f = Node::type_("f")
  @json.inspect(a.and_(b.or_(c)), content={
    "or": [{ "and": ["a", "b"] }, { "and": ["a", "c"] }],
  })
  @json.inspect(a.or_(b).and_(c.or_(d)), content={
    "or": [
      { "and": ["a", "c"] },
      {
        "or": [
          { "and": ["a", "d"] },
          { "or": [{ "and": ["b", "c"] }, { "and": ["b", "d"] }] },
        ],
      },
    ],
  })
  @json.inspect(a.and_(b).not(), content={
    "or": [{ "not": "a" }, { "not": "b" }],
  })
  @json.inspect(a.or_(b).not().and_(c), content={
    "and": [{ "not": "a" }, { "and": [{ "not": "b" }, "c"] }],
  })
  @json.inspect(a.and_(b).or_(a.not().and_(c)), content={
    "or": [{ "and": ["a", "b"] }, { "and": [{ "not": "a" }, "c"] }],
  })
  @json.inspect(a.and_(b.or_(b.not())), content="a")
  @json.inspect(a.or_(b.and_(b.not())), content="a")
  @json.inspect(a.and_(b).or_(a.and_(b.not())), content={
    "or": [{ "and": ["a", "b"] }, { "and": ["a", { "not": "b" }] }],
  })
  @json.inspect(a.not().or_(b.and_(c)).not(), content={
    "or": [{ "and": ["a", { "not": "b" }] }, { "and": ["a", { "not": "c" }] }],
  })
  @json.inspect(a.or_(b).and_(c.or_(d)).and_(e.or_(f)), content={
    "or": [
      { "and": ["a", { "and": ["c", "e"] }] },
      {
        "or": [
          { "and": ["a", { "and": ["c", "f"] }] },
          {
            "or": [
              { "and": ["a", { "and": ["d", "e"] }] },
              {
                "or": [
                  { "and": ["a", { "and": ["d", "f"] }] },
                  {
                    "or": [
                      { "and": ["b", { "and": ["c", "e"] }] },
                      {
                        "or": [
                          { "and": ["b", { "and": ["c", "f"] }] },
                          {
                            "or": [
                              { "and": ["b", { "and": ["d", "e"] }] },
                              { "and": ["b", { "and": ["d", "f"] }] },
                            ],
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    ],
  })
}

///|
fn Node::simplify(self : Node) -> Node {
  match self {
    True => True
    False => False
    And(n1, n2) => n1.simplify().and_(n2.simplify())
    Or(n1, n2) => n1.simplify().or_(n2.simplify())
    Not(n1) => n1.simplify().not()
    Type(t) => Type(t)
    Child(e) => Child(e.simplify())
    Descendant(e) => Descendant(e.simplify())
  }
}

///|
fn merge(
  self : Map[String, Array[Match]],
  other : Map[String, Array[Match]]
) -> Unit {
  for name, captures in other {
    if self.get(name) is Some(existing) {
      existing.append(captures)
    } else {
      self[name] = captures
    }
  }
}

///|
fn Node::matches(
  self : Node,
  node : @tree_sitter.Node
) -> Map[String, Array[Match]]? {
  println("Node::matches: expr = \{self}")
  println("Node::matches: node = \{node.type_()}")
  fn matches(
    self : Node,
    node : @tree_sitter.Node,
    group : Map[String, Array[Match]]
  ) -> Bool {
    let result = match self {
      True => true
      False => false
      And(n1, n2) => {
        let b1 = matches(n1, node, group)
        let b2 = matches(n2, node, group)
        b1 && b2
      }
      Or(n1, n2) => {
        let b1 = matches(n1, node, group)
        let b2 = matches(n2, node, group)
        b1 || b2
      }
      Not(n1) => not(matches(n1, node, group))
      Type(t) => if node.type_() == t { true } else { false }
      Child(e) =>
        if e.matches(node.children()) is Some(matched) {
          group.merge(matched.group)
          true
        } else {
          false
        }
      Descendant(e) =>
        matches(Child(e.alt(Repeat(Node(True)).seq(Node(self)))), node, group)
    }
    result
  }

  let group = Map::new()
  if matches(self, node, group) {
    Some(group)
  } else {
    None
  }
}

///|
enum Expr {
  Empty
  Never
  Node(Node)
  Seq(Expr, Expr)
  Alt(Expr, Expr)
  And(Expr, Expr)
  Repeat(Expr)
  Capture(Expr, String, id~ : Int?)
} derive(Eq, ToJson)

///|
impl Show for Expr with output(self : Expr, logger : &Logger) -> Unit {
  match self {
    Empty => logger.write_char('ε')
    Never => logger.write_char('⊥')
    Node(True) => logger.write_char('_')
    Node(n) => n.output(logger)
    Seq(e1, e2) => {
      e1.output(logger)
      logger.write_char(' ')
      e2.output(logger)
    }
    Alt(e1, e2) => {
      logger.write_char('(')
      e1.output(logger)
      logger.write_char('|')
      e2.output(logger)
      logger.write_char(')')
    }
    And(e1, e2) => {
      logger.write_char('(')
      e1.output(logger)
      logger.write_char('&')
      e2.output(logger)
      logger.write_char(')')
    }
    Repeat(Node(True) as n) | Repeat(Node(Type(_)) as n) => {
      n.output(logger)
      logger.write_char('*')
    }
    Repeat(e) => {
      logger.write_char('(')
      e.output(logger)
      logger.write_string(")*")
    }
    Capture(e, name, id~) => {
      logger.write_char('(')
      logger.write_string(name)
      if id is Some(id) {
        logger.write_string("@\{id}")
      }
      logger.write_char(':')
      e.output(logger)
      logger.write_char(')')
    }
  }
}

///|
fn Expr::simplify(self : Expr) -> Expr {
  match self {
    Empty => Empty
    Never => Never
    Node(n) => Node(n.simplify())
    Seq(e1, e2) => e1.simplify().seq(e2.simplify())
    Alt(e1, e2) => e1.simplify().alt(e2.simplify())
    And(e1, e2) => e1.simplify().and_(e2.simplify())
    Repeat(e) => e.simplify().repeat()
    Capture(e, name, id~) => e.simplify().capture(name, id?)
  }
}

///|
fn Expr::nullable(self : Expr) -> Bool {
  match self {
    Empty => true
    Never => false
    Node(_) => false
    Seq(e1, e2) => e1.nullable() && e2.nullable()
    Alt(e1, e2) => e1.nullable() || e2.nullable()
    And(e1, e2) => e1.nullable() && e2.nullable()
    Repeat(_) => true
    Capture(e, _, ..) => e.nullable()
  }
}

///|
pub fn Expr::seq(self : Expr, other : Expr) -> Expr {
  match (self, other) {
    (Empty, other) => other
    (_, Empty) => self
    (Never, _) => Never
    (_, Never) => Never
    (Seq(e1, e2), e3) => Seq(e1, e2.seq(e3))
    (e1, e2) => Seq(e1, e2)
  }
}

///|
pub fn Expr::alt(self : Expr, other : Expr) -> Expr {
  match (self, other) {
    (Never, _) => other
    (_, Never) => self
    (Alt(e1, e2), e3) => Alt(e1, e2.alt(e3))
    (e1, e2) if e1 == e2 => e1
    (e1, e2) => Alt(e1, e2)
  }
}

///|
pub fn Expr::and_(self : Expr, other : Expr) -> Expr {
  match (self, other) {
    (Empty, Empty) => Empty
    (Empty, other) => if other.nullable() { Empty } else { Never }
    (self, Empty) => if self.nullable() { Empty } else { Never }
    (Never, _) => Never
    (_, Never) => Never
    (Node(n1), Node(n2)) => Node(n1.and_(n2))
    (And(e1, e2), e3) => And(e1, e2.and_(e3))
    (e1, e2) => And(e1, e2)
  }
}

///|
pub fn Expr::repeat(self : Expr) -> Expr {
  match self {
    Empty => Empty
    Never => Never
    self => Repeat(self)
  }
}

///|
pub fn Expr::node(node : Node) -> Expr {
  Node(node)
}

///|
pub fn Expr::capture(self : Expr, name : String, id? : Int) -> Expr {
  match self {
    Never => Never
    self => Capture(self, name, id~)
  }
}

///|
priv struct State {
  nodes : Array[@tree_sitter.Node]
  start : Array[Int] // id -> start position
  end : Array[Int] // id -> end position
  table : Map[String, Array[Int]] // name -> ids
  group : Array[Map[String, Array[Match]]] // captures for each node
  ids : Array[Array[Int]] // ids for each node
} derive(Show, ToJson)

///|
fn State::new() -> State {
  { nodes: [], start: [], end: [], table: Map::new(), group: [], ids: [] }
}

///|
fn State::start(self : Self, name : String) -> Int {
  let id = self.start.length()
  let index = self.index()
  self.start.push(index)
  self.ids[index].push(id)
  self.end.push(-1)
  match self.table.get(name) {
    Some(ids) => ids.push(id)
    None => self.table[name] = [id]
  }
  id
}

///|
fn State::end(self : Self, id : Int) -> Unit {
  guard self.end[id] == -1
  self.end[id] = self.nodes.length()
}

///|
fn State::index(self : Self) -> Int {
  self.nodes.length()
}

///|
fn State::deriv(self : State, expr : Expr, node : @tree_sitter.Node) -> Expr {
  match expr {
    Empty => Never
    Never => Never
    Node(n) =>
      if n.matches(node) is Some(group) {
        self.group[self.index()].merge(group)
        Empty
      } else {
        Never
      }
    Seq(e1, e2) => {
      let d1 = self.deriv(e1, node)
      if e1.nullable() {
        d1.seq(e2).alt(self.deriv(e2, node))
      } else {
        d1.seq(e2)
      }
    }
    Alt(e1, e2) => self.deriv(e1, node).alt(self.deriv(e2, node))
    And(e1, e2) => self.deriv(e1, node).and_(self.deriv(e2, node))
    Repeat(e1) => self.deriv(e1, node).seq(expr)
    Capture(e1, name, ..) as capture => {
      let id = if capture.id is Some(id) { id } else { self.start(name) }
      let d1 = self.deriv(e1, node)
      if e1.nullable() && d1 is Never {
        self.end(id)
        Never
      } else {
        let r = d1.capture(name, id~)
        r
      }
    }
  }
}

///|
fn State::finish(self : State, expr : Expr) -> Bool {
  match expr {
    Empty => true
    Never => false
    Node(_) => false
    Seq(e1, e2) => {
      let b1 = self.finish(e1)
      let b2 = self.finish(e2)
      b1 && b2
    }
    Alt(e1, e2) => {
      let b1 = self.finish(e1)
      let b2 = self.finish(e2)
      b1 || b2
    }
    And(e1, e2) => {
      let b1 = self.finish(e1)
      let b2 = self.finish(e2)
      b1 && b2
    }
    Repeat(e1) => {
      ignore(self.finish(e1))
      true
    }
    Capture(e1, _, id=Some(id)) =>
      if self.finish(e1) {
        self.end(id)
        true
      } else {
        false
      }
    Capture(e1, _, id=None) => self.finish(e1)
  }
}

///|
priv struct Match {
  value : ArrayView[@tree_sitter.Node]
  group : Map[String, Array[Match]]
} derive(Show, ToJson)

///|
fn State::matches(
  self : State,
  expr : Expr,
  nodes : Iter[@tree_sitter.Node]
) -> Expr {
  let mut expr = expr
  for node in nodes {
    self.group.push({})
    self.ids.push([])
    expr = self.deriv(expr, node)
    if expr is Never {
      return Never
    }
    self.nodes.push(node)
  }
  expr
}

///|
fn Expr::matches(self : Expr, nodes : Iter[@tree_sitter.Node]) -> Match? {
  let state = State::new()
  let self = state.matches(self, nodes)
  if not(state.finish(self)) {
    return None
  }
  let matched = Map::new()
  for name, ids in state.table {
    let captures = []
    for id in ids {
      let start = state.start[id]
      let end = state.end[id]
      if end == -1 {
        continue
      }
      let group : Map[String, Array[Match]] = Map::new()
      for i in start..<end {
        group.merge(state.group[i])
      }
      captures.push({ value: state.nodes[start:end], group })
    }
    if not(captures.is_empty()) {
      matched[name] = captures
    }
  }
  for i, g in state.group {
    let mut count = 0
    for id in state.ids[i] {
      if state.end[id] != -1 {
        count += 1
      }
    }
    if count == 0 {
      matched.merge(g)
    }
  }
  Some({ value: state.nodes, group: matched })
}
