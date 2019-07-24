# Rewrite.jl

[![Travis Build Status](https://travis-ci.com/HarrisonGrodin/Rewrite.jl.svg?branch=master)](https://travis-ci.com/HarrisonGrodin/Rewrite.jl)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/rtaksxe4wu0j6xqv/branch/master?svg=true)](https://ci.appveyor.com/project/HarrisonGrodin/rewrite-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/HarrisonGrodin/Rewrite.jl/badge.svg?branch=master)](https://coveralls.io/github/HarrisonGrodin/Rewrite.jl?branch=master)

**Rewrite.jl** is an efficient symbolic term rewriting engine.


---

There are three primary steps in the development and use of a rewriting program:
1. Map each relevant function symbol to an equational theory. For example, we might specify that `+` is associative and commutative.
2. Define a system of rules to rewrite with respect to. For example, we might describe a desired rewrite from `x + 0` to `x`, for all `x`.
3. Rewrite a concrete term using the rules.


## Example

### Theory Definition

In this example, we'll simplify boolean propositions.

First, we'll define the theories which each function symbol belongs to. "Free" symbols follow no special axioms during matching, whereas AC symbols will match under [associativity](https://en.wikipedia.org/wiki/Associative_property) and [commutativity](https://en.wikipedia.org/wiki/Commutative_property).

```julia
@theory! begin
    F => FreeTheory()
    T => FreeTheory()
    (&) => ACTheory()
    (|) => ACTheory()
    (!) => FreeTheory()
end
```

Using the `@theory!` macro, we associate each of our symbols with a theory. Note that `F` and `T` will be a nullary (zero-argument) function, so we assign it the `FreeTheory`.

### Rules Definition

Given the defined theory, we now want to describe the rules which govern boolean logic. We include a handful of cases:

```julia
@rules Prop [x, y] begin
    x & F := F
    x & T := x

    x | F := x
    x | T := T

    !T := F
    !F := T

    !(x & y) := !x | !y
    !(x | y) := !x & !y
    !(!x)    := x
end
```

Naming the rewriting system `Prop` and using `x` as a variable, we define many rules. To verbalize a few of them:
- "`x` and false" is definitely false.
- "not true" is definitely false.
- "not (`x` and `y`)" is equivalent to "(not `x`) or (not `y`)".
- "not (not `x`)" is equivalent to whatever `x` is.

Under the hood, a custom function called `Prop` was defined, optimized for rewriting with these specific rules.

### Rewriting

Let's test it out on some concrete terms. First, we can evaluate some expressions which are based on constants:

```julia
julia> @rewrite(Prop, !(T & F) | !(!F))
@term(T())

julia> @rewrite(Prop, !(T & T) | !(!F | F))
@term(F())
```

We can also bring in our own custom symbols, which the system knows nothing about:

```julia
julia> @rewrite(Prop, a & (T & b) & (c & !F))
@term(&(a(), b(), c()))

julia> @rewrite(Prop, F | f(!(b & T)))
@term(f(!(b())))
```

Success! We've rewritten some boolean terms.
