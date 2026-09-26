module nonempty/test

import nonempty

// Every case below uses `assert`, which aborts the process on failure. Do not
// replace these with `val _ =`, which discards the result and always passes.

fun test-nonempty/single()
  val ne = nonempty/single(42)
  assert(r#"ne.head == 42"#, ne.head == 42)
  assert(r#"ne.tail == []"#, ne.tail == [])
  assert(r#"ne.length == 1"#, ne.length == 1)
  assert(r#"ne.last == 42"#, ne.last == 42)

fun test-cons()
  val ne = 1 <:: 2 <:: nonempty/single(3)
  assert(r#"ne.head == 1"#, ne.head == 1)
  assert(r#"ne.tail == [2, 3]"#, ne.tail == [2, 3])
  assert(r#"ne.length == 3"#, ne.length == 3)
  assert(r#"ne.last == 3"#, ne.last == 3)

fun test-list-conversion()
  val ne = 1 <:: nonempty/single(2)
  assert(r#"list(ne) == [1, 2]"#, list(ne) == [1, 2])
  val fromNothing : list<int> = nonempty/maybe/list(Nothing)
  val fromJust = nonempty/maybe/list(Just(ne))
  assert(r#"maybe/list(Nothing) == []"#, fromNothing == [])
  assert(r#"maybe/list(Just(ne)) == [1, 2]"#, fromJust == [1, 2])

fun test-nonempty-invariant()
  // The invariant must hold for every constructor, not just `single`.
  assert(r#"length(nonempty/single(0)) == 1"#, length(nonempty/single(0)) == 1)
  assert(r#"length(cons(0, nonempty/single(0))) == 2"#, length(cons(0, nonempty/single(0))) == 2)
  assert(r#"minimum(nonempty/single(7)) == 7"#, minimum(nonempty/single(7)) == 7)
  assert(r#"maximum(nonempty/single(7)) == 7"#, maximum(nonempty/single(7)) == 7)
  assert(r#"sum(nonempty/single(7)) == 7"#, sum(nonempty/single(7)) == 7)
  assert(r#"product(nonempty/single(7)) == 7"#, product(nonempty/single(7)) == 7)

fun test-append()
  val ne1 = 1 <:: nonempty/single(2)
  val ne2 = 3 <:: nonempty/single(4)
  assert(r#"(ne1 ++ ne2).list == [1, 2, 3, 4]"#, (ne1 ++ ne2).list == [1, 2, 3, 4])
  assert(r#"append(ne1, ne2).length == 4"#, append(ne1, ne2).length == 4)
  // Appending must not mutate the operands.
  assert(r#"ne1.list == [1, 2]"#, ne1.list == [1, 2])
  assert(r#"ne2.list == [3, 4]"#, ne2.list == [3, 4])

fun test-map()
  val ne = 1 <:: 2 <:: nonempty/single(3)
  val mapped = ne.map(fn(x) x * 2)
  assert(r#"mapped.list == [2, 4, 6]"#, mapped.list == [2, 4, 6])
  assert(r#"mapped.length == 3"#, mapped.length == 3)
  // Indices are zero-based, so the result is 0*10+1, 1*10+2, 2*10+3.
  val indexed = ne.map-indexed(fn(i, x) i * 10 + x)
  assert(r#"indexed.list == [1, 12, 23]"#, indexed.list == [1, 12, 23])

fun test-filter-may-empty()
  // `filter` must return `list`, not `nonempty`: the result can be empty.
  val ne = 1 <:: 2 <:: 3 <:: nonempty/single(4)
  assert(r#"ne.filter(fn(x) x % 2 == 0).list == [2, 4]"#, ne.filter(fn(x) x % 2 == 0) == [2, 4])
  assert(r#"empty filter yields []"#, ne.filter(fn(x) x > 99) == [])

fun test-queries()
  val ne = 1 <:: 2 <:: nonempty/single(3)
  assert(r#"find(x > 2) == Just(3)"#, find(ne, fn(x) x > 2) == Just(3))
  assert(r#"find(x > 9) == Nothing"#, find(ne, fn(x) x > 9) == Nothing)
  assert(r#"index-of(x == 2) == 1"#, index-of(ne, fn(x) x == 2) == 1)
  assert(r#"index-of(x == 9) == -1"#, index-of(ne, fn(x) x == 9) == -1)
  val has2 = nonempty/contains(ne, 2)
  val has9 = nonempty/contains(ne, 9)
  assert(r#"contains(2)"#, has2)
  assert(r#"not contains(9)"#, not(has9))
  val evens = 2 <:: 4 <:: nonempty/single(6)
  val allEven = all(evens, fn(x) x % 2 == 0)
  val anyOdd = any(evens, fn(x) x % 2 == 1)
  assert(r#"all(even)"#, allEven)
  assert(r#"not any(odd)"#, not(anyOdd))

fun test-folds-agree-with-length()
  val ne = 1 <:: 2 <:: 3 <:: nonempty/single(4)
  val add : (int, int) -> int = fn(a, b) a + b
  assert(r#"foldl == 10"#, foldl(ne, 0, add) == 10)
  assert(r#"foldr == 10"#, foldr(ne, 0, add) == 10)
  // A fold seeded with the first element must match the full fold.
  assert(r#"foldl1 == foldl without seed"#, foldl1(ne, add) == foldl(ne, 0, add))
  assert(r#"foldr1 == foldr without seed"#, foldr1(ne, add) == foldr(ne, 0, add))
  assert(r#"scanl.list == [0, 1, 3, 6, 10]"#, scanl(ne, 0, add).list == [0, 1, 3, 6, 10])
  assert(r#"scanr.length == 5"#, scanr(ne, 0, add).length == 5)

fun test-sorts()
  val ne = 3 <:: 1 <:: 4 <:: nonempty/single(2)
  assert(r#"sort.list == [1, 2, 3, 4]"#, nonempty/sort(ne).list == [1, 2, 3, 4])
  val byNeg = on/sort(ne, fn(x) 0 - x)
  assert(r#"on/sort on negated key"#, byNeg.list == [4, 3, 2, 1])
  val desc = nonempty/sort(ne, fn(x : int, y : int) y.cmp(x))
  assert(r#"descending sort"#, desc.list == [4, 3, 2, 1])

fun test-single-element-edges()
  // Sorting and reversing a one-element list are the common degenerate cases.
  assert(r#"nonempty/sort(nonempty/single(1)).list == [1]"#, nonempty/sort(nonempty/single(1)).list == [1])
  assert(r#"reverse(nonempty/single(1)).list == [1]"#, reverse(nonempty/single(1)).list == [1])
  assert(r#"reverse(nonempty/single(1)).length == 1"#, reverse(nonempty/single(1)).length == 1)
  assert(r#"intersperse(nonempty/single(1), 0).list == [1]"#, intersperse(nonempty/single(1), 0).list == [1])
  assert(r#"zip(nonempty/single(1), nonempty/single(2)).list == [(1, 2)]"#, zip(nonempty/single(1), nonempty/single(2)).list == [(1, 2)])

fun test-reverse-roundtrip()
  val ne = 1 <:: 2 <:: 3 <:: nonempty/single(4)
  assert(r#"reverse.list == [4, 3, 2, 1]"#, reverse(ne).list == [4, 3, 2, 1])
  assert(r#"reverse twice is identity"#, reverse(reverse(ne)).list == [1, 2, 3, 4])

fun test-uncons-unsnoc()
  val ne = 1 <:: 2 <:: nonempty/single(3)
  val (h, mt) = uncons(ne)
  assert(r#"h == 1"#, h == 1)
  assert(r#"mt == Just(2 <:: nonempty/single(3))"#, mt == Just(2 <:: nonempty/single(3)))
  val (mi, l) = unsnoc(ne)
  assert(r#"mi == Just([1, 2])"#, mi == Just([1, 2]))
  assert(r#"l == 3"#, l == 3)
  // A single element has no nonempty tail and no nonempty init.
  val (h1, mt1) = uncons(nonempty/single(1))
  assert(r#"single uncons tail is Nothing"#, mt1 == Nothing)
  val (mi1, l1) = unsnoc(nonempty/single(1))
  assert(r#"single unsnoc init is Nothing"#, mi1 == Nothing)
  assert(r#"single unsnoc last"#, l1 == 1)

fun test-concat()
  val nes = (1 <:: nonempty/single(2)) <:: (3 <:: nonempty/single(4)) <:: nonempty/single(5 <:: nonempty/single(6))
  assert(r#"concat.list == [1..6]"#, concat(nes).list == [1, 2, 3, 4, 5, 6])
  assert(r#"concat preserves length"#, concat(nes).length == 6)

fun test-intersperse()
  val ne = 1 <:: 2 <:: nonempty/single(3)
  // The separator goes strictly between elements, so n elements yield n - 1
  // separators.
  assert(r#"intersperse(0).list == [1, 0, 2, 0, 3]"#, intersperse(ne, 0).list == [1, 0, 2, 0, 3])
  assert(r#"two elements get one separator"#, intersperse(1 <:: nonempty/single(2), 0).list == [1, 0, 2])

fun test-zip-unzip-roundtrip()
  val ne1 = 1 <:: 2 <:: nonempty/single(3)
  val ne2 = "a" <:: "b" <:: nonempty/single("c")
  val (a, b) = zip(ne1, ne2).unzip
  assert(r#"unzip first"#, a.list == [1, 2, 3])
  assert(r#"unzip second"#, b.list == ["a", "b", "c"])
  // zip truncates to the shorter input but must not lose the invariant.
  val short = zip(ne1, nonempty/single("z"))
  assert(r#"zip truncates to shorter"#, short.list == [(1, "z")])
  assert(r#"zip keeps nonempty"#, short.length == 1)

fun test-flatmap()
  val ne = 1 <:: 2 <:: nonempty/single(3)
  val flat = flatmap(ne, fn(x) x <:: nonempty/single(x * 2))
  assert(r#"flatmap.list"#, flat.list == [1, 2, 2, 4, 3, 6])
  assert(r#"flatmap length"#, flat.length == 6)

fun test-list-interop()
  val ne = 1 <:: nonempty/single(2)
  assert(r#"list/append.list == [1, 2, 3, 4]"#, nonempty/list/append(ne, [3, 4]).list == [1, 2, 3, 4])
  assert(r#"list/prepend.list == [9, 1, 2]"#, nonempty/list/prepend([9], ne).list == [9, 1, 2])
  val fromEmpty : maybe<nonempty<int>> = nonempty/list/nonempty([])
  val fromOne = nonempty/list/nonempty([1])
  assert(r#"list/nonempty([]) == Nothing"#, fromEmpty == Nothing)
  assert(r#"list/nonempty([1]).is-just"#, fromOne.is-just)

fun test-take-drop-span()
  val ne = 1 <:: 2 <:: 3 <:: 4 <:: nonempty/single(5)
  assert(r#"take(3)"#, take(ne, 3) == [1, 2, 3])
  assert(r#"drop(2)"#, drop(ne, 2) == [3, 4, 5])
  // n defaults to length, so these are identity.
  assert(r#"take default"#, take(ne) == ne.list)
  assert(r#"drop default"#, drop(ne) == [])
  val (p, s) = span(ne, fn(x) x < 3)
  assert(r#"span prefix"#, p == [1, 2])
  assert(r#"span suffix"#, s == [3, 4, 5])

fun test-equality-and-cmp()
  val ne1 = 1 <:: 2 <:: nonempty/single(3)
  val ne2 = 1 <:: 2 <:: nonempty/single(3)
  val ne3 = 1 <:: 2 <:: nonempty/single(4)
  assert(r#"equal"#, ne1 == ne2)
  assert(r#"not equal"#, not (ne1 == ne3))
  assert(r#"cmp equal"#, ne1.cmp(ne2) == Eq)
  assert(r#"cmp less"#, ne1.cmp(1 <:: 3 <:: nonempty/single(2)) == Lt)
  assert(r#"cmp greater"#, (1 <:: 3 <:: nonempty/single(2)).cmp(ne1) == Gt)

fun test-show()
  assert(r#"show"#, (1 <:: 2 <:: nonempty/single(3)).show == "Nonempty(head=1, tail=[2,3])")

fun test-lookup-join()
  val ne = (1, "one") <:: (2, "two") <:: nonempty/single((3, "three"))
  assert(r#"lookup"#, lookup(ne, fn(k) k == 2) == Just("two"))
  assert(r#"lookup miss"#, lookup(ne, fn(k) k == 9) == Nothing)
  val words = "a" <:: "b" <:: nonempty/single("c")
  assert(r#"join-end"#, join-end(words, ",") == "a,b,c,")
  assert(r#"join-end single"#, join-end(nonempty/single("a"), ",") == "a,")

fun test-unfoldr()
  val ne = unfoldr(1, fn(x) if x > 3 then (x, Nothing) else (x, Just(x + 1)))
  assert(r#"unfoldr.list"#, ne.list == [1, 2, 3, 4])
  // A predicate that stops immediately still yields a nonempty result.
  val one = unfoldr(1, fn(x) (x, Nothing))
  assert(r#"unfoldr immediate stop"#, one.list == [1])
  assert(r#"unfoldr immediate stop length"#, one.length == 1)

fun test-init-last()
  val ne = 1 <:: 2 <:: nonempty/single(3)
  assert(r#"last"#, last(ne) == 3)
  assert(r#"init"#, init(ne) == [1, 2])
  // init of a single element is empty, which is why its type is `list`.
  assert(r#"init of single is empty"#, init(nonempty/single(1)) == [])

fun main()
  test-nonempty/single()
  test-cons()
  test-list-conversion()
  test-nonempty-invariant()
  test-append()
  test-map()
  test-filter-may-empty()
  test-queries()
  test-folds-agree-with-length()
  test-sorts()
  test-single-element-edges()
  test-reverse-roundtrip()
  test-uncons-unsnoc()
  test-concat()
  test-intersperse()
  test-zip-unzip-roundtrip()
  test-flatmap()
  test-list-interop()
  test-take-drop-span()
  test-equality-and-cmp()
  test-show()
  test-lookup-join()
  test-unfoldr()
  test-init-last()
  "All tests passed!"
