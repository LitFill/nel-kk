# TODOs

- [x] add `list/cons(:a, :list<a>) :nonempty<a>` and `list/(<::)` alias. [^1]

## References

[^1]:
    so user could use it like `1 <:: 2 <:: [3]` where the first operator is
    the `(:a, :nonempty<a>) -> nonempty<a>` and the second is `(:a, :list<a>) :
nonempty<a>`.
