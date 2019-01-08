# Terms.jl

[![Travis Build Status](https://travis-ci.com/HarrisonGrodin/Terms.jl.svg?branch=master)](https://travis-ci.com/HarrisonGrodin/Terms.jl)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/rtaksxe4wu0j6xqv/branch/master?svg=true)](https://ci.appveyor.com/project/HarrisonGrodin/terms-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/HarrisonGrodin/Terms.jl/badge.svg?branch=master)](https://coveralls.io/github/HarrisonGrodin/Terms.jl?branch=master)

**Terms.jl** provides performance-oriented symbolic term utilities.


## Features

Terms.jl exports the following features. For the remainder of the document, we assume that the package has been installed and loaded.

```julia
using Terms
```

Every term `t::Term` wraps an object from the Julia AST, namely an `Expr` or a constant. We retrieve the root value of `t` using `root(t)` and the child terms using `children(t)::Vector{Term}`.

```julia
k = 2
t = convert(Term, :(f(g(a), $k)))  # f(g(a), 2)

@assert root(t) == :call
@assert children(t) == [convert(Term, :f), convert(Term, :(g(a))), convert(Term, k)]
```


### Pattern Creation and Usage

It is often useful to represent terms following a given structure abstractly, leaving syntactic variables in place of an arbitrary term. Thus, we provide the `Variable` constructor as follows. Note that each call to `Variable` produces a unique new variable.

```julia
x = Variable()
p = convert(Term, :(m ^ $x - n))
```

**Note:** `Variable` is used to represent an arbitrary symbolic term, *not* an unknown parameter value.

#### Matching

Given a pattern `p::Term` and a subject `s::Term` of the same structure, we can generate a substitution `σ::Substitution` such that applying the substitution to `p` results in `s`, or `σ(p) == s`, as follows.

```julia
s = convert(Term, :(m ^ (a + b) - n))
σ = match(p, s)

@assert σ[x] == convert(Term, :(a + b))
@assert σ(p) == s
```

If the matching procedure fails, `nothing` is returned.

```julia
s′ = convert(Term, :(k ^ (a + b) - n))
σ′ = match(p, s′)

@assert σ′ === nothing
```

#### Unification

Syntactic unification is planned but not currently included.


## Acknowledgements
- [*Term Rewriting and All That*](https://www21.in.tum.de/~nipkow/TRaAT/)
- @YingboMa
