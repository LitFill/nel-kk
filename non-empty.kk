module non-empty

pub infixr 5 (<::)

// Non-empty list type with at least one element.
// The head is always present; tail is a regular list that may be empty.
pub struct non-empty<a>
  head : a
  tail : list<a>

// Construct a non-empty list from a single element.
pub fun single(x) Non-empty(x, [])

// Prepend an element to a non-empty list.
pub fun cons(x : a, ne : non-empty<a>) : non-empty<a>
  Non-empty(x, ne.list)

// Infix operator for prepending. Right-associative with precedence 5.
pub fun (<::)(x, ne) cons(x, ne)

// Convert to a regular list.
pub fun list(ne : non-empty<a>) : list<a>
  Cons(ne.head, ne.tail)

/// Convert a maybe non-empty to a regular list (empty if Nothing).
pub fun maybe/list(mne : maybe<non-empty<a>>) : list<a>
  match mne
    Nothing -> []
    Just(ne) -> ne.list

// Number of elements. Always at least 1.
pub fun length(ne : non-empty<a>) : int
  ne.tail.length + 1

// The last element.
pub fun last(ne : non-empty<a>) : a
  ne.tail.last.default(ne.head)

// All elements except the last. Returns a regular list for it may be empty.
pub fun init(ne : non-empty<a>) : list<a>
  ne.list.init

// Split a list into (init, last) or Nothing if empty.
pub fun list/unsnoc(xs : list<a>) : maybe<(list<a>, a)>
  match xs
    Nil -> Nothing
    Cons(x, xx) -> match xx.unsnoc
      Nothing -> Just((Nil, x))
      Just((ys, y)) -> Just((Cons(x, ys), y))

// Split a list into (init, last) using maybe2.
pub fun list/unsnoc'(xs : list<a>) : maybe2<list<a>, a>
  match xs
    Nil -> Nothing2
    Cons(x, xx) -> match xx.unsnoc'
      Nothing2 -> Just2(Nil, x)
      Just2(ys, y) -> Just2(Cons(x, ys), y)

// Deconstruct into head and optional tail as non-empty.
// Returns (head, Just(tail)) if tail non-empty, else (head, Nothing).
pub fun uncons(ne : non-empty<a>) : (a, maybe<non-empty<a>>)
  (ne.head, ne.tail.non-empty)

// Deconstruct into optional init and last.
// Returns (Nothing, last) for single-element, else (Just(init), last).
pub fun unsnoc(ne : non-empty<a>) : (maybe<list<a>>, a)
  match ne.tail.unsnoc
    Nothing -> (Nothing, ne.head)
    Just((xs, x)) -> (ne.head.Cons(xs).Just, x)

// Structural equality.
pub fun eq(no__derived_eq_1 : non-empty<a>, no__derived_eq_2 : non-empty<a>, ?a/(==) : (a, a) -> bool)
  no__derived_eq_1.head == no__derived_eq_2.head
  && no__derived_eq_1.tail == no__derived_eq_2.tail

// Infix structural equality.
pub fun (==)(x : non-empty<a>, y : non-empty<a>, ?a/(==) : (a, a) -> bool)
  non-empty/eq(x, y)

// Show instance.
pub fun show(no__derived_show : non-empty<a>, ?a/show : a -> string)
  "Non-empty("
  ++ "head=" ++ no__derived_show.head.show ++ ", "
  ++ "tail=" ++ no__derived_show.tail.show()
  ++ ")"

// Map a function over all elements.
pub fun map(ne : non-empty<a>, f : a -> e b) : e non-empty<b>
  Non-empty(ne.head.f, ne.tail.map(f))

// Map a function over all elements with their index.
pub fun map-indexed(ne : non-empty<a>, f : (ix : int, x : a) -> e b) : e non-empty<b>
  Non-empty( head = f(0, ne.head)
           , tail = ne.tail.map-indexed fn(i, x) f(i + 1, x))

// Left fold with initial accumulator.
pub fun foldl(ne : non-empty<a>, z : b, f : (b, a) -> e b) : e b
  ne.tail.foldl(f(z, ne.head), f)

// Left fold with no initial accumulator (uses head as initial).
pub fun foldl1(ne : non-empty<a>, f : (a, a) -> e a) : e a
  ne.tail.foldl(ne.head, f)

// Right fold with initial accumulator.
pub fun foldr(ne : non-empty<a>, z : b, f : (a, b) -> e b) : e b
  ne.list.foldr(z, f)

// Right fold with no initial accumulator.
pub fun foldr1(ne : non-empty<a>, f : (a, a) -> e a) : e a
  match ne.unsnoc
    (Nothing, last)  -> last
    (Just(xs), last) -> xs.foldr(last, f)

// Left scan: returns non-empty list of intermediate accumulators including initial.
pub fun scanl(ne : non-empty<a>, z : b, f : (b, a) -> e b) : e non-empty<b>
  Non-empty(z, ne.tail.scanl(f(z, ne.head), f))

// Right scan: returns non-empty list of intermediate accumulators including initial.
pub fun scanr(ne : non-empty<a>, z : b, f : (a, b) -> e b) : e non-empty<b>
  val xs = ne.tail.scanr(z, f)
  Non-empty(
    head = f(ne.head, xs.head(z)),
    // Koka cannot infer scans never produce empty list
    tail = xs
  )

// Left scan with no initial accumulator (uses head as initial).
pub fun one/scanl(ne : non-empty<a>, f : (a, a) -> e a) : e non-empty<a>
  val xs = ne.tail.scanl(ne.head, f)
  Non-empty(
    head = xs.head(ne.head),
    // Koka cannot infer scans never produce empty list
    tail = xs.tail
  )

// Right scan with no initial accumulator.
pub fun one/scanr(ne : non-empty<a>, f : (a, a) -> e a) : e non-empty<a>
  val xs = ne.tail.scanr(ne.head, f)
  Non-empty(
    head = xs.head(ne.head),
    // Koka cannot infer scans never produce empty list
    tail = xs.tail
  )

// List variant of left scan.
pub fun list/scanl(xs : list<a>, z : b, f : (b, a) -> e b) : e list<b>
  match xs
    Nil         -> [z]
    Cons(x, xx) -> z.Cons(xx.scanl(f(z, x), f))

// List variant of right scan.
pub fun list/scanr(xs : list<a>, z : b, f : (a, b) -> e b) : e list<b>
  match xs
    Nil         -> [z]
    Cons(x, xx) ->
      val qs = xx.scanr(z, f)
      f(x, qs.head(z)).Cons(qs)

// Apply an action to each element for effect.
pub fun foreach(ne : non-empty<a>, action : a -> e ()) : e ()
  ne.list.foreach(action)

// Apply an action to each element with its index for effect.
pub fun foreach-indexed(ne : non-empty<a>, action : (ix : int, x : a) -> e ()) : e ()
  ne.list.foreach-indexed(action)

// Apply an action to each element until it returns Just.
pub fun foreach-while(ne : non-empty<a>, action : a -> e maybe<b>) : e maybe<b>
  ne.list.foreach-while(action)

// Append a list to a non-empty list.
pub fun list/append(ne : non-empty<a>, xs : list<a>) : non-empty<a>
  ne(tail = ne.tail ++ xs)

// Infix operator for appending a list.
pub fun list/(++)(ne : non-empty<a>, xs : list<a>) : non-empty<a>
  append(ne, xs)

// Append two non-empty lists.
pub fun append(n : non-empty<a>, m : non-empty<a>) : non-empty<a>
  n(tail = n.tail ++ m.list)

// Infix operator for appending two non-empty lists.
pub fun (++)(n : non-empty<a>, m : non-empty<a>) : non-empty<a>
  append(n, m)

// Prepend a list to a non-empty list.
pub fun list/prepend(xs : list<a>, ne : non-empty<a>) : non-empty<a>
  match xs
    Nil -> ne
    Cons(x, xx) -> Non-empty(x, xx ++ ne.tail)

// Concatenate a non-empty list of non-empty lists.
pub fun concat(nes : non-empty<non-empty<a>>) : non-empty<a>
  Non-empty( head = nes.head.head
           , tail = nes.head.tail ++ nes.tail.map(_.list).concat)

// Concatenate a list of non-empty lists into a regular list.
pub fun list/concat(nes : list<non-empty<a>>) : list<a>
  nes.map(_.list).concat

// Append an element to a list.
pub fun list/snoc(xs : list<a>, x : a) : list<a>
  xs ++ [x]

// Take first n elements as a regular list.
pub fun take(ne : non-empty<a>, n : int = ne.length) : list<a>
  ne.list.take(n)

// Drop first n elements as a regular list.
pub fun drop(ne : non-empty<a>, n : int = ne.length) : list<a>
  ne.list.drop(n)

// Split at index n into (prefix, suffix) as regular lists.
pub fun split(ne : non-empty<a>, n : int) : (list<a>, list<a>)
  ne.list.split(n)

// Take elements while predicate holds.
pub fun take-while(ne : non-empty<a>, pred : a -> e bool) : e list<a>
  ne.list.take-while(pred)

// Drop elements while predicate holds.
pub fun drop-while(ne : non-empty<a>, pred : a -> e bool) : e list<a>
  ne.list.drop-while(pred)

// Split into (longest prefix where pred holds, remainder).
pub fun span(ne : non-empty<a>, pred : a -> e bool) : e (list<a>, list<a>)
  ne.list.span(pred)

// Filter elements by predicate, returning a regular list (may be empty).
pub fun filter(ne : non-empty<a>, pred : a -> e bool) : e list<a>
  ne.list.filter(pred)

// Map to maybe and collect Just values, returning a regular list.
pub fun filter-map(ne : non-empty<a>, pred : a -> e maybe<b>) : e list<b>
  ne.list.filter-map(pred)

// True if all elements satisfy predicate.
pub fun all(ne : non-empty<a>, pred : a -> e bool) : e bool
  ne.map(pred).foldl(True, _&&_)

// True if any element satisfies predicate.
pub fun any(ne : non-empty<a>, pred : a -> e bool) : e bool
  ne.map(pred).foldl(False, _||_)

// Find first element satisfying predicate.
pub fun find(ne : non-empty<a>, pred : a -> e bool) : e maybe<a>
  ne.list.find(pred)

// Find first Just result of mapping predicate.
pub fun find-maybe(ne : non-empty<a>, pred : a -> e maybe<b>) : e maybe<b>
  ne.list.find-maybe(pred)

// Index of first element satisfying predicate, or -1.
pub fun index-of(ne : non-empty<a>, pred : a -> e bool) : e int
  ne.list.index-of(pred)

// Check if element exists (uses equality).
pub fun contains(ne : non-empty<a>, x : a, ?(==) : (a, a) -> bool) : bool
  ne.list.contains(x)

// Flatmap: map to non-empty and concatenate.
pub fun flatmap(ne : non-empty<a>, f : a -> e non-empty<b>) : e non-empty<b>
  ne.map(f).concat

// Flatmap to maybe and collect Just values into a regular list.
pub fun flatmap-maybe(ne : non-empty<a>, f : a -> e maybe<b>) : e list<b>
  ne.list.flatmap-maybe(f)

// Intersperse an element between all elements.
pub fun intersperse(ne : non-empty<a>, a : a) : non-empty<a>
  ne(tail=a.Cons(ne.tail.intersperse(a)))

// Reverse the non-empty list.
pub fun reverse(ne : non-empty<a>) : non-empty<a>
  ne.list.reverse.non-empty.default(ne)

// Sort using comparison function.
pub fun sort(ne : non-empty<a>, ?cmp : (a, a) -> e order) : e non-empty<a>
  match ne
    Non-empty(x, xs) ->
      val sorted = insert(x, xs.sort)
      sorted.non-empty.default(ne)

// Sort by key function.
pub fun on/sort(ne : non-empty<a>, f : a -> e b, ?cmp : (b, b) -> e order) : e non-empty<a>
  ne.sort fn(x, y) cmp(f(x), f(y))

// List insert for sorting.
pub fun list/insert(x : a, xs : list<a>, ?cmp : (a, a) -> e order) : e list<a>
  match xs
    [] -> [x]
    Cons(y, yy) ->
      if x <= y
      then Cons(x, Cons(y, yy))
      else Cons(y, insert(x, yy))

// List sort.
pub fun list/sort(xs : list<a>, ?cmp : (a, a) -> e order) : e list<a>
  match xs
    Cons(x, xx) -> insert(x, xx.sort)
    Nil -> Nil

// List sort by key.
pub fun list/on/sort(xs : list<a>, f : a -> e b, ?cmp : (b, b) -> e order) : e list<a>
  xs.sort fn(x, y) cmp(f(x), f(y))

// Lexicographic comparison.
pub fun cmp(n : non-empty<a>, m : non-empty<a>, ?cmp : (a, a) -> e order) : e order
  cmp(n.list, m.list)

// Maximum element (for int).
pub fun maximum(ne : non-empty<int>) : int
  ne.tail.maximum(ne.head)

// Minimum element (for int).
pub fun minimum(ne : non-empty<int>) : int
  ne.tail.minimum(ne.head)

// Maximum element using custom comparison.
pub fun default/maximum(ne : non-empty<a>, ?cmp : (a, a) -> e order) : e a
  ne.sort.last

// Minimum element using custom comparison.
pub fun default/minimum(ne : non-empty<a>, ?cmp : (a, a) -> e order) : e a
  ne.sort.head

// Sum of elements (requires +).
pub fun sum(ne : non-empty<a>, ?(+) : (a, a) -> e a) : e a
  ne.tail.foldl(ne.head, _+_)

// Product of elements (requires *).
pub fun product(ne : non-empty<a>, ?(*) : (a, a) -> e a) : e a
  ne.tail.foldl(ne.head, _*_)

// Zip two non-empty lists element-wise. Truncates to shorter length.
pub fun zip(n : non-empty<a>, m : non-empty<b>) : non-empty<(a, b)>
  Non-empty( head =    (n.head, m.head)
           , tail = zip(n.tail, m.tail))

// Unzip a non-empty list of pairs.
pub fun unzip(ne : non-empty<(a, b)>) : (non-empty<a>, non-empty<b>)
  ( Non-empty(ne.head.fst, ne.tail.unzip.fst)
  , Non-empty(ne.head.snd, ne.tail.unzip.snd)
  )

// Zip with a combining function.
pub fun zip-with(n : non-empty<a>, m : non-empty<b>, f : (a, b) -> e c) : e non-empty<c>
  Non-empty( head =       f(n.head, m.head)
           , tail = zipWith(n.tail, m.tail, f))

// Convert a list to non-empty, returning Nothing if empty.
pub fun list/non-empty(xs : list<a>) : maybe<non-empty<a>>
  match xs
    Nil -> Nothing
    Cons(x, xx) -> Just(Non-empty(x, xx))

// Convert a list to non-empty, raising an exception if empty.
pub fun list/exn/non-empty'(xs : list<a>) : exn non-empty<a>
  xs.non-empty.expect("non-empty: unexpected empty list")

// Unfold a non-empty list from a seed.
// Function returns (element, maybe next-seed). Nothing terminates.
pub fun unfoldr(x : b, f : b -> <div|e> (a, maybe<b>)) : <div|e> non-empty<a>
  match f(x)
    (a, Nothing) -> single(a)
    (a, Just(b)) -> Non-empty(a, unfoldr(b, f).list)

// List variant of unfoldr.
pub fun list/unfoldr(x : b, f : b -> <div|e> maybe2<a, b>) : <div|e> list<a>
  match f(x)
    Nothing2    -> []
    Just2(a, b) -> Cons(a, unfoldr(b, f))

// Lookup value by key predicate in a non-empty list of pairs.
pub fun lookup(ne : non-empty<(k, v)>, pred : k -> e bool) : e maybe<v>
  ne.list.lookup(pred)

// Join string elements with a separator appended after each.
pub fun join-end(ne : non-empty<string>, end : string) : string
  ne.head ++ end ++ ne.tail.join-end(end)

// Entry point.
fun main()
  "Hello, Koka!"
