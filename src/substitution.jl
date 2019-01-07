export match


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


Base.replace(t::Term{T}, σ::AbstractDict) where {T} =
    isa(t.head, Variable) ? get(σ, t.head, t) : Term{T}(t.head, replace.(t.args, Ref(σ)))


"""
    match(pattern::Term, subject::Term) -> σ::Union{Substitution, Nothing}

Syntactically match term `subject` to `pattern`, producing a `Substitution` if the
process succeeds and `nothing` otherwise.
"""
Base.match(pattern::Term, subject::Term) = _match!(Substitution(), pattern, subject)

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
