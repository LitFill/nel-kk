module utils

/// Function utility: gather spreads a tuple argument.
pub fun function/gather(action : (f : (a : a, b : b) -> e c) -> e d, body : (p : (a, b)) -> e c) : e d
  action(spread(body))

/// Convert a function taking a pair to a function taking two arguments.
pub fun function/spread(f : (p : (a, b)) -> e c) : ((a : a, b : b) -> e c)
  fn(a, b) f((a, b))

/// Three-argument gather: applies a function to a triple.
pub fun function/three/gather(action : (f : (a, b, c) -> e d) -> e f, body : (t : (a, b, c)) -> e d) : e f
  action(three/spread(body))

/// Convert a function taking a triple to a function taking three arguments.
pub fun function/three/spread(f : (t : (a, b, c)) -> e d) : ((a : a, b : b, c : c) -> e d)
  fn(a, b, c) f((a, b, c))

/// Test helper for gather.
fun test-gather()
  with p <- gather(list('a', 'z').foreach-indexed(_))
  val (ix, x) = p
  (ix + 1).show.pad-left(3).print; ": ".print
  [x].string.println

/// Entry point.
fun main()
  "Hello, Koka!"