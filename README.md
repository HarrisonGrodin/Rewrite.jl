# Terms.jl

[![Travis Build Status](https://travis-ci.com/HarrisonGrodin/Terms.jl.svg?branch=master)](https://travis-ci.com/HarrisonGrodin/Terms.jl)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/rtaksxe4wu0j6xqv/branch/master?svg=true)](https://ci.appveyor.com/project/HarrisonGrodin/terms-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/HarrisonGrodin/Terms.jl/badge.svg?branch=master)](https://coveralls.io/github/HarrisonGrodin/Terms.jl?branch=master)

**Terms.jl** provides performance-oriented representations of symbolic terms and relevant functions.

The central types are both *fast* and *flexible*, allowing for type-level specialization when more information is known about values stored within the term.
Features are presented with an emphasis on modularity, giving clients the ability to balance simplicity with speed.


## Features

Terms.jl exports the following features. For the remainder of the document, we assume that the package has been installed and loaded.

```julia
using Terms
```

### Term Representation

Every term `t::Term{T}` is represented as a plane tree, with `t.head::T` containing the root and `t.args::Vector{Term{T}}` containing the ordered vector of child trees. If `t.args` is empty, `t` is treated as a leaf node. Note that the parameter `T` restricts which types of values may be stored in `t`.

```julia
const SymTerm = Term{Symbol}

# f(g(a), b)
t = SymTerm(:f, [SymTerm(:g, [SymTerm(:a)]), SymTerm(:b)])
```

This style of term construction is sufficient under the assumption that we only care to represent first-order function calls. However, in the case that we want to store more complex syntactic features and higher-order functions, we can naturally transform an expression represented using the built-in `Expr` type into a `Term`.

```julia
# :(identity(+)(x, y))
u = SymTerm(:call, [SymTerm(:call, [SymTerm(:identity), SymTerm(:+)]), SymTerm(:x), SymTerm(:y)])

u′ = convert(SymTerm, :(identity(+)(x, y)))

@assert u == u′
```

### Substitution Generation

It is often useful to represent terms following a given structure abstractly, leaving syntactic variables in place of an arbitrary term. Thus, we provide the `Variable` constructor as follows. Note that each call to `Variable` produces a unique new variable.

```julia
const SymPattern = Pattern{Symbol}  # alias for Term{Union{Symbol, Variable}}

x = Variable()
p = convert(SymPattern, :(m ^ $x - n))
```

**Note:** `Variable` is used to represent an arbitrary symbolic term, *not* an unknown parameter value.

#### Matching

Given a pattern `p::Term` and a subject `s::Term` of the same structure, we can generate a substitution `σ::Substitution` such that applying the substitution to `p` results in `s`, or `σ(p) == s`, as follows.

```julia
s = convert(SymTerm, :(m ^ (a + b) - n))
σ = match(p, s)

@assert σ[x] == convert(SymTerm, :(a + b))
@assert σ(p) == s
```

If the matching procedure fails, `nothing` is returned.

```julia
s′ = convert(SymTerm, :(k ^ (a + b) - n))
σ′ = match(p, s′)

@assert σ′ === nothing
```

#### Unification

Syntactic unification is planned but not currently included.

### Constant Pooling

In order to improve performance during critical operations, we can assign all constants within a term a unique identifier of a fixed type, guaranteeing type stability during term manipulations. This is the purpose of a constant pool.

We register an expression with a constant pool as follows, using `push!` to insert the expression into the pool and `getindex` to generate an expression using the pool.

```julia
pool = Pool{Union{Symbol, Int}}()

expr = :(2 ^ k - 1)
term = push!(pool, expr)
@assert pool[term] == expr
```

**Note:** We do not pool `Variable` objects due to their unique meaning during matching.


## Acknowledgements
- [*Term Rewriting and All That*](https://www21.in.tum.de/~nipkow/TRaAT/)
- @YingboMa
