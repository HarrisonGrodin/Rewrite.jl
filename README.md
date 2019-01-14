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

Every term `t::Term` wraps an object from the Julia AST, namely an `Expr` or a constant. We retrieve the root value of `t` using `t.head` and the child terms using `t.args::Vector{Term}`.

```julia
k = 2
t = @term(mod(k ^ 5, 3))  # mod(2 ^ 5, 3)

@assert t.head == :call
@assert t.args == [@term(mod), @term(k ^ 5), @term 3]
```


### Pattern Creation and Usage

It is often useful to represent terms following a given structure abstractly, leaving syntactic variables in place of an arbitrary term. Thus, we provide the `Variable` constructor as follows. Note that each call to `Variable` produces a unique new variable.

```julia
x = Variable()
p = @term(2 ^ x - 1)
```

**Note:** `Variable` is used to represent an arbitrary symbolic term, *not* an unknown parameter value.

#### Matching

Given a pattern `p::Term` and a subject `s::Term` of the same structure, we can generate a substitution `σ::Substitution` such that applying the substitution to `p` results in `s`, or `σ(p) == s`, as follows.

```julia
s = @term(2 ^ (sin(π / 2) + 3) - 1)
σ = match(p, s)

@assert σ[x] == @term(sin(π / 2) + 3)
@assert σ(p) == s
```

If the matching procedure fails, `nothing` is returned.

```julia
s′ = @term(3 ^ 5 - 1)
σ′ = match(p, s′)

@assert σ′ === nothing
```

#### Unification

Syntactic unification is planned but not currently included.


## Acknowledgements
- [*Term Rewriting and All That*](https://www21.in.tum.de/~nipkow/TRaAT/)
- [@YingboMa](https://github.com/YingboMa)
- [@MasonProtter](https://github.com/MasonProtter)
