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
