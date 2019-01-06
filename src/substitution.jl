export match


struct Substitution <: AbstractDict{Leaf,Tree}
    dict::Dict{Leaf,Tree}
end
Substitution() = Substitution(Dict{Leaf,Tree}())
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
Base.replace(t::Branch, σ::AbstractDict) = Branch(t.head, replace.(t.args, σ))
Base.replace(t::Leaf, σ::AbstractDict) = t.kind === VARIABLE ? get(σ, t, t) : t


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
    if isa(p, Leaf)
        p.kind === CONSTANT &&
            return (isa(s, Leaf) && s.index === p.index) ? σ : nothing

        # @assert p.kind === VARIABLE
        haskey(σ, p) && σ[p] != s && return nothing
        σ[p] = s
        return σ
    end

    # @assert isa(p, Branch)
    if isa(s, Branch)
        p.head === s.head                || return nothing
        length(p.args) == length(s.args) || return nothing

        for (x, y) ∈ zip(p.args, s.args)
            σ′ = _match!(σ, x, y)
            σ′ === nothing && return nothing
            σ = σ′
        end

        return σ
    end

    return nothing
end
