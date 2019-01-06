export match


"""
    match(pattern::Term, subject::Term) -> σ::Union{Substitution, Nothing}

Syntactically match term `subject` to `pattern`, producing a `Substitution` if the
process succeeds and `nothing` otherwise.
"""
function Base.match(pattern::Term, subject::Term)
    pattern.builder === subject.builder ||
        throw(ArgumentError("pattern and subject must have same builder"))

    _match(Substitution(), pattern.tree, subject.tree)
end

function _match(σ::Substitution, p::Leaf, s)
    p.kind === CONSTANT && return is_leaf(s) && s.index === p.index ? σ : nothing

    @assert p.kind === VARIABLE
    haskey(σ, p) && σ[p] != s && return nothing
    σ[p] = s
    return σ
end
function _match(σ::Substitution, p::Branch, s::Branch)
    p.head === s.head                || return nothing
    length(p.args) == length(s.args) || return nothing

    for (x, y) ∈ zip(p.args, s.args)
        σ = _match(σ, x, y)
        σ === nothing && return nothing
    end

    σ
end
_match(::Substitution, ::Any, ::Any) = nothing
