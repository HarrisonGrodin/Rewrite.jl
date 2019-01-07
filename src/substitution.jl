export Variable, Pattern
export Substitution
export match


mutable struct Variable end
Base.promote_rule(::Type{Variable}, T::Type) = Union{Variable, T}
Base.promote_rule(::Type{Variable}, ::Type{Any}) = Any

const Pattern{T} = Term{Union{Variable, T}}


struct Substitution{T} <: AbstractDict{Variable,Term{T}}
    dict::Dict{Variable,Term{T}}
end
Substitution{T}() where {T} = Substitution(Dict{Variable,Term{T}}())
(σ::Substitution)(t) = replace(t, σ)
Base.length(σ::Substitution) = length(σ.dict)
Base.iterate(σ::Substitution) = iterate(σ.dict)
Base.iterate(σ::Substitution, state) = iterate(σ.dict, state)
Base.keys(σ::Substitution) = keys(σ.dict)
Base.getindex(σ::Substitution, keys...) = getindex(σ.dict, keys...)
Base.setindex!(σ::Substitution, val, keys...) = (setindex!(σ.dict, val, keys...); σ)
Base.get(σ::Substitution, key, default) = get(σ.dict, key, default)


Base.replace(t::Term{T}, σ::AbstractDict) where {T} =
    isa(t.head, Variable) ? get(σ, t.head, t) : Term{T}(t.head, replace.(t.args, Ref(σ)))


"""
    match(pattern::Term, subject::Term) -> σ::Union{Substitution, Nothing}

Syntactically match term `subject` to `pattern`, producing a `Substitution` such that
`σ(pattern) == subject` if the process succeeds and `nothing` otherwise.

# Examples
```jldoctest
julia> x = Variable()
Variable()

julia> pattern = convert(Pattern{Symbol}, :(\$x + f(\$x)));

julia> subject1 = convert(Term{Symbol}, :(ka + f(ka)));

julia> σ = match(pattern, subject1);

julia> σ[x]
Term{Symbol}(:ka, Term{Symbol}[])

julia> σ(subject1) == subject1
true

julia> subject2 = convert(Term{Symbol}, :(p + f(q)));

julia> match(pattern, subject2)
```
"""
Base.match(pattern::Term, subject::Term{T}) where {T} =
    _match!(Substitution{T}(), pattern, subject)

function _match!(σ::Substitution, p::Term, s::Term)
    if isa(p.head, Variable)
        x = p.head
        haskey(σ, x) && (isequal(σ[x], s) || return)
        return setindex!(σ, s, x)  # σ[p] = s
    end

    isequal(p.head, s.head)          || return
    length(p.args) == length(s.args) || return

    for (x, y) ∈ zip(p.args, s.args)
        σ′ = _match!(σ, x, y)
        σ′ === nothing && return
        σ = σ′
    end

    return σ
end
