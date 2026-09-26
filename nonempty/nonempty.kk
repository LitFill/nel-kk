module nonempty

pub infixr 5 (<::)

// nonempty list type with at least one element.
// The head is always present; tail is a regular list that may be empty.
pub struct nonempty<a>
  head : a
  tail : list<a>

// Construct a nonempty list from a single element.
pub fun single(x) Nonempty(x, [])

// Prepend an element to a nonempty list.
pub fun cons(x : a, ne : nonempty<a>) : nonempty<a>
  Nonempty(x, ne.list)

// Infix operator for prepending. Right-associative with precedence 5.
pub fun (<::)(x, ne) cons(x, ne)

// Convert to a regular list.
pub fun list(ne : nonempty<a>) : list<a>
  Cons(ne.head, ne.tail)

// Convert a maybe nonempty to a regular list (empty if Nothing).
pub fun maybe/list(mne : maybe<nonempty<a>>) : list<a>
  match mne
    Nothing  -> []
    Just(ne) -> ne.list

// Number of elements. Always at least 1.
pub fun length(ne : nonempty<a>) : int
  ne.tail.length + 1

// The last element.
pub fun last(ne : nonempty<a>) : a
  ne.tail.last.default(ne.head)

// All elements except the last. Returns a regular list for it may be empty.
pub fun init(ne : nonempty<a>) : list<a>
  ne.list.init

// Split a list into (init, last) or Nothing if empty.
pub fun list/unsnoc(xs : list<a>) : maybe<(list<a>, a)>
  match xs
    Nil         -> Nothing
    Cons(x, xx) -> match xx.unsnoc
      Nothing       -> Just((Nil, x))
      Just((ys, y)) -> Just((Cons(x, ys), y))

// Split a list into (init, last) using maybe2.
pub fun list/unsnoc'(xs : list<a>) : maybe2<list<a>, a>
  match xs
    Nil         -> Nothing2
    Cons(x, xx) -> match xx.unsnoc'
      Nothing2     -> Just2(Nil, x)
      Just2(ys, y) -> Just2(Cons(x, ys), y)

// Deconstruct into head and optional tail as nonempty.
// Returns (head, Just(tail)) if tail nonempty, else (head, Nothing).
pub fun uncons(ne : nonempty<a>) : (a, maybe<nonempty<a>>)
  (ne.head, ne.tail.nonempty)

// Deconstruct into optional init and last.
// Returns (Nothing, last) for single-element, else (Just(init), last).
pub fun unsnoc(ne : nonempty<a>) : (maybe<list<a>>, a)
  match ne.tail.unsnoc
    Nothing       -> (Nothing, ne.head)
    Just((xs, x)) -> (ne.head.Cons(xs).Just, x)

// Structural equality.
pub fun eq(no__derived_eq_1 : nonempty<a>, no__derived_eq_2 : nonempty<a>, ?a/(==) : (a, a) -> bool)
  no__derived_eq_1.head == no__derived_eq_2.head
  && no__derived_eq_1.tail == no__derived_eq_2.tail

// Infix structural equality.
pub fun (==)(x : nonempty<a>, y : nonempty<a>, ?a/(==) : (a, a) -> bool)
  nonempty/eq(x, y)

// Show instance.
pub fun show(no__derived_show : nonempty<a>, ?a/show : a -> string)
  "Nonempty("
  ++ "head=" ++ no__derived_show.head.show ++ ", "
  ++ "tail=" ++ no__derived_show.tail.show()
  ++ ")"

// Map a function over all elements.
pub fun map(ne : nonempty<a>, f : a -> e b) : e nonempty<b>
  Nonempty(ne.head.f, ne.tail.map(f))

// Map a function over all elements with their index.
pub fun map-indexed(ne : nonempty<a>, f : (ix : int, x : a) -> e b) : e nonempty<b>
  Nonempty( head = f(0, ne.head)
          , tail = ne.tail.map-indexed fn(i, x) f(i + 1, x))

// Left fold with initial accumulator.
pub fun foldl(ne : nonempty<a>, z : b, f : (b, a) -> e b) : e b
  ne.tail.foldl(f(z, ne.head), f)

// Left fold with no initial accumulator (uses head as initial).
pub fun foldl1(ne : nonempty<a>, f : (a, a) -> e a) : e a
  ne.tail.foldl(ne.head, f)

// Right fold with initial accumulator.
pub fun foldr(ne : nonempty<a>, z : b, f : (a, b) -> e b) : e b
  ne.list.foldr(z, f)

// Right fold with no initial accumulator.
pub fun foldr1(ne : nonempty<a>, f : (a, a) -> e a) : e a
  match ne.unsnoc
    (Nothing, last)  -> last
    (Just(xs), last) -> xs.foldr(last, f)

// Left scan: returns nonempty list of intermediate accumulators including initial.
pub fun scanl(ne : nonempty<a>, z : b, f : (b, a) -> e b) : e nonempty<b>
  Nonempty(z, ne.tail.scanl(f(z, ne.head), f))

// Right scan: returns nonempty list of intermediate accumulators including initial.
pub fun scanr(ne : nonempty<a>, z : b, f : (a, b) -> e b) : e nonempty<b>
  val xs = ne.tail.scanr(z, f)
  Nonempty(
    head = f(ne.head, xs.head(z)),
    // Koka cannot infer scans never produce empty list
    tail = xs
  )

// Left scan with no initial accumulator (uses head as initial).
pub fun one/scanl(ne : nonempty<a>, f : (a, a) -> e a) : e nonempty<a>
  val xs = ne.tail.scanl(ne.head, f)
  Nonempty(
    head = xs.head(ne.head),
    // Koka cannot infer scans never produce empty list
    tail = xs.tail
  )

// Right scan with no initial accumulator.
pub fun one/scanr(ne : nonempty<a>, f : (a, a) -> e a) : e nonempty<a>
  val xs = ne.tail.scanr(ne.head, f)
  Nonempty(
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
pub fun foreach(ne : nonempty<a>, action : a -> e ()) : e ()
  ne.list.foreach(action)

// Apply an action to each element with its index for effect.
pub fun foreach-indexed(ne : nonempty<a>, action : (ix : int, x : a) -> e ()) : e ()
  ne.list.foreach-indexed(action)

// Apply an action to each element until it returns Just.
pub fun foreach-while(ne : nonempty<a>, action : a -> e maybe<b>) : e maybe<b>
  ne.list.foreach-while(action)

// Append a list to a nonempty list.
pub fun list/append(ne : nonempty<a>, xs : list<a>) : nonempty<a>
  ne(tail = ne.tail ++ xs)

// Infix operator for appending a list.
pub fun list/(++)(ne : nonempty<a>, xs : list<a>) : nonempty<a>
  append(ne, xs)

// Append two nonempty lists.
pub fun append(n : nonempty<a>, m : nonempty<a>) : nonempty<a>
  n(tail = n.tail ++ m.list)

// Infix operator for appending two nonempty lists.
pub fun (++)(n : nonempty<a>, m : nonempty<a>) : nonempty<a>
  append(n, m)

// Prepend a list to a nonempty list.
pub fun list/prepend(xs : list<a>, ne : nonempty<a>) : nonempty<a>
  match xs
    Nil         -> ne
    Cons(x, xx) -> Nonempty(x, xx ++ ne.list)

// Concatenate a nonempty list of nonempty lists.
pub fun concat(nes : nonempty<nonempty<a>>) : nonempty<a>
  Nonempty( head = nes.head.head
          , tail = nes.head.tail ++ nes.tail.map(_.list).concat)

// Concatenate a list of nonempty lists into a regular list.
pub fun list/concat(nes : list<nonempty<a>>) : list<a>
  nes.map(_.list).concat

// Append an element to a list.
pub fun list/snoc(xs : list<a>, x : a) : list<a>
  xs ++ [x]

// Take first n elements as a regular list.
pub fun take(ne : nonempty<a>, n : int = ne.length) : list<a>
  ne.list.take(n)

// Drop first n elements as a regular list.
pub fun drop(ne : nonempty<a>, n : int = ne.length) : list<a>
  ne.list.drop(n)

// Split at index n into (prefix, suffix) as regular lists.
pub fun split(ne : nonempty<a>, n : int) : (list<a>, list<a>)
  ne.list.split(n)

// Take elements while predicate holds.
pub fun take-while(ne : nonempty<a>, pred : a -> e bool) : e list<a>
  ne.list.take-while(pred)

// Drop elements while predicate holds.
pub fun drop-while(ne : nonempty<a>, pred : a -> e bool) : e list<a>
  ne.list.drop-while(pred)

// Split into (longest prefix where pred holds, remainder).
pub fun span(ne : nonempty<a>, pred : a -> e bool) : e (list<a>, list<a>)
  ne.list.span(pred)

// Filter elements by predicate, returning a regular list (may be empty).
pub fun filter(ne : nonempty<a>, pred : a -> e bool) : e list<a>
  ne.list.filter(pred)

// Map to maybe and collect Just values, returning a regular list.
pub fun filter-map(ne : nonempty<a>, pred : a -> e maybe<b>) : e list<b>
  ne.list.filter-map(pred)

// True if all elements satisfy predicate.
pub fun all(ne : nonempty<a>, pred : a -> e bool) : e bool
  ne.map(pred).foldl(True, _&&_)

// True if any element satisfies predicate.
pub fun any(ne : nonempty<a>, pred : a -> e bool) : e bool
  ne.map(pred).foldl(False, _||_)

// Find first element satisfying predicate.
pub fun find(ne : nonempty<a>, pred : a -> e bool) : e maybe<a>
  ne.list.find(pred)

// Find first Just result of mapping predicate.
pub fun find-maybe(ne : nonempty<a>, pred : a -> e maybe<b>) : e maybe<b>
  ne.list.find-maybe(pred)

// Index of first element satisfying predicate, or -1.
pub fun index-of(ne : nonempty<a>, pred : a -> e bool) : e int
  ne.list.index-of(pred)

// Check if element exists (uses equality).
pub fun contains(ne : nonempty<a>, x : a, ?(==) : (a, a) -> bool) : bool
  ne.list.contains(x)

// Flatmap: map to nonempty and concatenate.
pub fun flatmap(ne : nonempty<a>, f : a -> e nonempty<b>) : e nonempty<b>
  ne.map(f).concat

// Flatmap to maybe and collect Just values into a regular list.
pub fun flatmap-maybe(ne : nonempty<a>, f : a -> e maybe<b>) : e list<b>
  ne.list.flatmap-maybe(f)

// Intersperse an element between all elements.
pub fun intersperse(ne : nonempty<a>, a : a) : nonempty<a>
  // Interspersing only the tail would drop the separator between the head and
  // the first tail element, so the whole list is interspersed and re-wrapped.
  // The result is nonempty because the input is.
  match ne.list.intersperse(a)
    Cons(x, xs) -> Nonempty(x, xs)
    Nil         -> ne

// Reverse the nonempty list.
pub fun reverse(ne : nonempty<a>) : nonempty<a>
  ne.list.reverse.nonempty.default(ne)

// Sort using comparison function.
pub fun sort(ne : nonempty<a>, ?cmp : (a, a) -> e order) : e nonempty<a>
  match ne
    Nonempty(x, xs) ->
      val sorted = insert(x, xs.sort)
      sorted.nonempty.default(ne)

// Sort by key function.
pub fun on/sort(ne : nonempty<a>, f : a -> e b, ?cmp : (b, b) -> e order) : e nonempty<a>
  ne.sort fn(x, y) cmp(f(x), f(y))

// List insert for sorting.
pub fun list/insert(x : a, xs : list<a>, ?cmp : (a, a) -> e order) : e list<a>
  match xs
    []          -> [x]
    Cons(y, yy) ->
      if x <= y
      then Cons(x, Cons(y, yy))
      else Cons(y, insert(x, yy))

// List sort.
pub fun list/sort(xs : list<a>, ?cmp : (a, a) -> e order) : e list<a>
  match xs
    Cons(x, xx) -> insert(x, xx.sort)
    Nil         -> Nil

// List sort by key.
pub fun list/on/sort(xs : list<a>, f : a -> e b, ?cmp : (b, b) -> e order) : e list<a>
  xs.sort fn(x, y) cmp(f(x), f(y))

// Lexicographic comparison.
pub fun cmp(n : nonempty<a>, m : nonempty<a>, ?cmp : (a, a) -> e order) : e order
  cmp(n.list, m.list)

// Maximum element (for int).
pub fun maximum(ne : nonempty<int>) : int
  ne.tail.maximum(ne.head)

// Minimum element (for int).
pub fun minimum(ne : nonempty<int>) : int
  ne.tail.minimum(ne.head)

// Maximum element using custom comparison.
pub fun default/maximum(ne : nonempty<a>, ?cmp : (a, a) -> e order) : e a
  ne.sort.last

// Minimum element using custom comparison.
pub fun default/minimum(ne : nonempty<a>, ?cmp : (a, a) -> e order) : e a
  ne.sort.head

// Sum of elements (requires +).
pub fun sum(ne : nonempty<a>, ?(+) : (a, a) -> e a) : e a
  ne.tail.foldl(ne.head, _+_)

// Product of elements (requires *).
pub fun product(ne : nonempty<a>, ?(*) : (a, a) -> e a) : e a
  ne.tail.foldl(ne.head, _*_)

// Zip two nonempty lists element-wise. Truncates to shorter length.
pub fun zip(n : nonempty<a>, m : nonempty<b>) : nonempty<(a, b)>
  Nonempty( head =    (n.head, m.head)
          , tail = zip(n.tail, m.tail))

// Unzip a nonempty list of pairs.
pub fun unzip(ne : nonempty<(a, b)>) : (nonempty<a>, nonempty<b>)
  ( Nonempty(ne.head.fst, ne.tail.unzip.fst)
  , Nonempty(ne.head.snd, ne.tail.unzip.snd)
  )

// Zip with a combining function.
pub fun zip-with(n : nonempty<a>, m : nonempty<b>, f : (a, b) -> e c) : e nonempty<c>
  Nonempty( head =       f(n.head, m.head)
          , tail = zipWith(n.tail, m.tail, f))

// Convert a list to nonempty, returning Nothing if empty.
pub fun list/nonempty(xs : list<a>) : maybe<nonempty<a>>
  match xs
    Nil         -> Nothing
    Cons(x, xx) -> Just(Nonempty(x, xx))

// Convert a list to nonempty, raising an exception if empty.
pub fun list/exn/nonempty'(xs : list<a>) : exn nonempty<a>
  xs.nonempty.expect("nonempty: unexpected empty list")

// Unfold a nonempty list from a seed.
// Function returns (element, maybe next-seed). Nothing terminates.
pub fun unfoldr(x : b, f : b -> <div|e> (a, maybe<b>)) : <div|e> nonempty<a>
  match f(x)
    (a, Nothing) -> single(a)
    (a, Just(b)) -> Nonempty(a, unfoldr(b, f).list)

// List variant of unfoldr.
pub fun list/unfoldr(x : b, f : b -> <div|e> maybe2<a, b>) : <div|e> list<a>
  match f(x)
    Nothing2    -> []
    Just2(a, b) -> Cons(a, unfoldr(b, f))

// Lookup value by key predicate in a nonempty list of pairs.
pub fun lookup(ne : nonempty<(k, v)>, pred : k -> e bool) : e maybe<v>
  ne.list.lookup(pred)

// Join string elements with a separator appended after each.
pub fun join-end(ne : nonempty<string>, end : string) : string
  ne.head ++ end ++ ne.tail.join-end(end)

// Dummy entry point.
fun main()
  "Hello, Koka!"
