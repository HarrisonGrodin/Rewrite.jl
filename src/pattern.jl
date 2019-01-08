export Variable, Pattern
export Substitution
export match


mutable struct Variable end


struct Substitution <: AbstractDict{Variable,Any}
    dict::Dict{Variable,Any}
end
Substitution() = Substitution(Dict{Variable,Any}())
(σ::Substitution)(t) = replace(t, σ)
Base.length(σ::Substitution) = length(σ.dict)
Base.iterate(σ::Substitution) = iterate(σ.dict)
Base.iterate(σ::Substitution, state) = iterate(σ.dict, state)
Base.keys(σ::Substitution) = keys(σ.dict)
Base.getindex(σ::Substitution, keys...) = Term(getindex(σ.dict, keys...))
Base.setindex!(σ::Substitution, val, keys...) = (setindex!(σ.dict, val, keys...); σ)
Base.setindex!(σ::Substitution, val::Term, keys...) = setindex!(σ, val.x, keys...)
Base.get(σ::Substitution, key, default) = get(σ.dict, key, default)


Base.replace(t::Term, σ::AbstractDict) = convert(Term, _replace(t, σ))
_replace(t, σ) = isa(root(t), Variable) ? get(σ, root(t), t) : map(x -> replace(x, σ), t)


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
    _match!(Substitution(), _unwrap(pattern), _unwrap(subject))

function _match!(σ::Substitution, p, s)
    if isa(p, Variable)
        haskey(σ, p) && return isequal(σ[p].x, s) ? σ : nothing
        return setindex!(σ, s, p)  # σ[p] = s
    end

    isa(p, Expr) || return isequal(p, s) ? σ : nothing
    isa(s, Expr) || return

    p.head === s.head                || return
    length(p.args) == length(s.args) || return

    for (x, y) ∈ zip(p.args, s.args)
        σ′ = _match!(σ, x, y)
        σ′ === nothing && return
        σ = σ′
    end

    return σ
end
