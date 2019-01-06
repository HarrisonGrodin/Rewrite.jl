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
Base.setindex!(σ::Substitution, val, keys...) = setindex!(σ.dict, val, keys...)
Base.get(σ::Substitution, key, default) = get(σ.dict, key, default)
Base.broadcastable(σ::Substitution) = Ref(σ)


Base.replace(t::Term, σ::AbstractDict) = Term(replace(t.tree, σ), t.builder)
Base.replace(t::Node, σ::AbstractDict) = Node(t.head, replace.(t.args, σ))
Base.replace(t::Variable, σ::AbstractDict) = get(σ, t, t)


"""
    match(pattern::Term, subject::Term) -> σ::Union{Substitution, Nothing}

Syntactically match term `subject` to `pattern`, producing a `Substitution` if the
process succeeds and `nothing` otherwise.
"""
function Base.match(pattern::Term, subject::Term)
    pattern.builder === subject.builder ||
        throw(ArgumentError("pattern and subject must have same builder"))

    _match!(Substitution(), pattern.tree, subject.tree)
end

function _match!(σ::Substitution, p, s)
    if isa(p, Variable)
        haskey(σ, p) && σ[p] != s && return nothing
        σ[p] = s
        return σ
    end

    isa(s, Node) || return nothing

    # @assert isa(p, Node)
    p.head === s.head                || return nothing
    length(p.args) == length(s.args) || return nothing

    # @assert isa(p.head, Symbol)
    for (x, y) ∈ zip(p.args, s.args)
        σ′ = _match!(σ, x, y)
        σ′ === nothing && return nothing
        σ = σ′
    end

    return σ
end
