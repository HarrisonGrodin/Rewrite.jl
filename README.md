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

Every term `t::Term` represents an abstract syntax tree. We retrieve the root value of `t` using `root(t)` and the child terms using `children(t)::Vector{Term}`.

```julia
k = 2
t = @term(mod(k ^ 5, 3))  # mod(2 ^ 5, 3)

@assert root(t) == :call
@assert children(t) == [@term(mod), @term(k ^ 5), @term 3]
```

Additionally, we can retrieve a subterm using standard indexing notation, `t[inds...]`.

```julia
@assert t[2] == @term(2 ^ 5)
@assert t[2,1] == @term(^)
```

#### Example: In-Order Traversal

```julia
function leaves(t::Term)
    isleaf(t) && return Any[root(t)]

    ls = Any[]
    for i ∈ eachindex(t)
        append!(ls, inord(t[i]))
    end
    return ls
end

@assert leaves(t) == [mod, ^, 2, 5, 3]
@assert leaves(@term((1 + 2) * (3 + 4))) == [*, +, 1, 2, +, 3, 4]
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
