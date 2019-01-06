export Variable, Pool, Term


mutable struct Variable end


struct Node
    head::Union{Symbol, UInt}
    args::Vector{Union{Node, Variable}}
end
Base.:(==)(s::Node, t::Node) = (s.head, s.args) == (t.head, t.args)

const Tree = Union{Node, Variable}


struct Pool{T}
    ids::Dict{T,UInt}
    lookup::Vector{T}
    Pool{T}() where {T} = new{T}(Dict{T,UInt}(), T[])
end
Base.broadcastable(p::Pool) = Ref(p)
function Base.push!(p::Pool, x)
    haskey(p.ids, x) && return p.ids[x]

    push!(p.lookup, x)
    index = UInt(length(p.lookup))
    p.ids[x] = index
    return index
end
Base.getindex(p::Pool, index::UInt) = p.lookup[index]


struct Term{T}
    tree::Tree
    pool::Pool{T}
end
(p::Pool)(ex) = Term(expr_to_tree(p, ex), p)
Base.convert(::Type{Expr}, t::Term) = term_to_expr(t)

Base.:(==)(s::Term, t::Term) = s.pool === t.pool && s.tree == t.tree
