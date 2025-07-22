///|
test "roundtrip" {
  let sexp =
    #|(a b c d: (f g))
    #|(h (j) (k (l)))
  let sexp = @sexp.parse(sexp)
  inspect(
    @sexp.print(sexp),
    content=(
      #|(a
      #| b
      #| c
      #| d: (f
      #|     g))
      #|(h
      #| (j)
      #| (k
      #|  (l)))
    ),
  )
}

///|
test "brackets" {
  let sexp =
    #|[a b c d: [f g]]
    #|[h [j] [k [l]]]
  let sexp = @sexp.parse(sexp)
  inspect(
    @sexp.print(sexp),
    content=(
      #|[a
      #| b
      #| c
      #| d: [f
      #|     g]]
      #|[h
      #| [j]
      #| [k
      #|  [l]]]
    ),
  )
}

///|
test "capture" {
  let sexp =
    #|((capture a) @a)
  let sexp = @sexp.parse(sexp)
  inspect(
    @sexp.print(sexp),
    content=(
      #|((capture
      #|  a) @a)
    ),
  )
}

///|
test "comment" {
  let sexp =
    #|; comment a
    #|a b c d: (f g) ; comment b
    #|; comment c
    #|(h (j) ; command d
    #|   (k (l)) ; comment e
    #|)
    #|
    #|(a b ; comment
    #|   c ; comment
    #|   d e f)
  let sexp = @sexp.parse(sexp)
  @json.inspect(sexp, content=[
    "; comment a",
    "a",
    "b",
    "c",
    "d:",
    ["f", "g"],
    "; comment b",
    "; comment c",
    ["h", ["j"], "; command d", ["k", ["l"]], "; comment e"],
    ["a", "b", "; comment", "c", "; comment", "d", "e", "f"],
  ])
  inspect(
    @sexp.print(sexp),
    content=(
      #|; comment a
      #|a
      #|b
      #|c
      #|d: (f
      #|    g)
      #|; comment b
      #|; comment c
      #|(h
      #| (j)
      #| ; command d
      #| (k
      #|  (l))
      #| ; comment e
      #|)
      #|(a
      #| b
      #| ; comment
      #| c
      #| ; comment
      #| d
      #| e
      #| f)
    ),
  )
}

///|
test "newline" {
  let sexp =
    #|a
    #|
    #|(b
    #|
    #|  c)
  let sexp = @sexp.parse(sexp)
  @json.inspect(sexp, content=["a", ["b", "c"]])
  inspect(
    @sexp.print(sexp),
    content=(
      #|a
      #|(b
      #| c)
    ),
  )
}
