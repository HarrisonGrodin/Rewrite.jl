export Variable, Pool, Term


mutable struct Variable end


struct Node
    head::Union{Symbol, UInt}
    args::Vector{Union{Node, Variable}}
end
Base.:(==)(s::Node, t::Node) = (s.head, s.args) == (t.head, t.args)

const Tree = Union{Node, Variable}


struct Pool{T}
    insert::Dict{T,UInt}
    lookup::Dict{UInt,T}
    count::Base.RefValue{UInt}
    Pool{T}() where {T} = new{T}(Dict{T,UInt}(), Dict{UInt,T}(), Ref(zero(UInt)))
end
Base.broadcastable(p::Pool) = Ref(p)
function Base.push!(p::Pool, x)
    haskey(p.insert, x) && return p.insert[x]
    index = (p.count[] += one(UInt))
    p.insert[x] = index
    p.lookup[index] = x
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
