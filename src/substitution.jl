export match


struct Substitution <: AbstractDict{Variable,Tree}
    dict::Dict{Variable,Tree}
end
Substitution() = Substitution(Dict{Variable,Tree}())
(σ::Substitution)(t) = replace(t, σ)
Base.length(σ::Substitution) = length(σ.dict)
Base.iterate(σ::Substitution) = iterate(σ.dict)
Base.iterate(σ::Substitution, state) = iterate(σ.dict, state)
Base.keys(σ::Substitution) = keys(σ.dict)
Base.getindex(σ::Substitution, keys...) = getindex(σ.dict, keys...)
Base.setindex!(σ::Substitution, val, keys...) = (setindex!(σ.dict, val, keys...); σ)
Base.get(σ::Substitution, key, default) = get(σ.dict, key, default)


Base.replace(t::Term{T}, σ::AbstractDict) where {T} = Term{T}(replace(t.tree, σ))
Base.replace(t::Tree{T}, σ::AbstractDict) where {T} =
    isa(t, Variable) ? get(σ, t, t) :
    isa(t, Node)     ? Node{T}(t.head, replace.(t.args, Ref(σ))) :
    t


"""
    match(pattern::Term, subject::Term) -> σ::Union{Substitution, Nothing}

Syntactically match term `subject` to `pattern`, producing a `Substitution` if the
process succeeds and `nothing` otherwise.
"""
Base.match(pattern::Term, subject::Term) =
    _match!(Substitution(), pattern.tree, subject.tree)

function _match!(σ::Substitution, p, s)
    if isa(p, Variable)
        haskey(σ, p) && (isequal(σ[p], s) || return)
        return setindex!(σ, s, p)  # σ[p] = s
    end
    # @assert isa(p, Node)

    isa(s, Node) || return
    # @assert isa(s, Node)

    isequal(p.head, s.head)          || return
    length(p.args) == length(s.args) || return

    for (x, y) ∈ zip(p.args, s.args)
        σ′ = _match!(σ, x, y)
        σ′ === nothing && return
        σ = σ′
    end

    return σ
end
