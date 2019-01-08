export Variable, Pattern
export Substitution
export match


mutable struct Variable end


struct Substitution <: AbstractDict{Variable,Term}
    dict::Dict{Variable,Term}
end
Substitution() = Substitution(Dict{Variable,Term}())
(σ::Substitution)(t) = replace(t, σ)
Base.length(σ::Substitution) = length(σ.dict)
Base.iterate(σ::Substitution) = iterate(σ.dict)
Base.iterate(σ::Substitution, state) = iterate(σ.dict, state)
Base.keys(σ::Substitution) = keys(σ.dict)
Base.getindex(σ::Substitution, keys...) = getindex(σ.dict, keys...)
Base.setindex!(σ::Substitution, val, keys...) = (setindex!(σ.dict, val, keys...); σ)
Base.get(σ::Substitution, key, default) = get(σ.dict, key, default)


Base.replace(t::Term, σ::AbstractDict) =
    isa(root(t), Variable) ? get(σ, root(t), t) : map(x -> replace(x, σ), t)


"""
    match(pattern::Term, subject::Term) -> σ::Union{Substitution, Nothing}

Syntactically match term `subject` to `pattern`, producing a `Substitution` such that
`σ(pattern) == subject` if the process succeeds and `nothing` otherwise.

# Examples
```jldoctest
julia> x = Variable()
Variable()

julia> pattern = convert(Term, :(\$x + f(\$x)));

julia> subject1 = convert(Term, :(ka + f(ka)));

julia> σ = match(pattern, subject1);

julia> σ[x]
convert(Term, :ka)

julia> σ(subject1) == subject1
true

julia> subject2 = convert(Term, :(p + f(q)));

julia> match(pattern, subject2)
```
"""
Base.match(pattern::Term, subject::Term) =
    _match!(Substitution(), pattern, subject)

function _match!(σ::Substitution, p, s)
    x = root(p)
    if isa(x, Variable)
        haskey(σ, x) && (isequal(σ[x], s) || return)
        return setindex!(σ, s, x)  # σ[x] = s
    end

    is_branch(p) || return isequal(p, s) ? σ : nothing
    is_branch(s) || return

    root(p) == root(s)               || return

    ps, ss = children(p), children(s)
    length(ps) == length(ss) || return

    for (x, y) ∈ zip(ps, ss)
        σ′ = _match!(σ, x, y)
        σ′ === nothing && return
        σ = σ′
    end

    return σ
end
