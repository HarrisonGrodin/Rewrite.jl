export Variable, TermBuilder, Term


const Index = UInt32


mutable struct Variable end


struct Node
    head::Union{Symbol, Index}
    args::Vector{Union{Node, Variable}}
end
Base.:(==)(s::Node, t::Node) = (s.head, s.args) == (t.head, t.args)

const Tree = Union{Node, Variable}


struct TermBuilder{T}
    insert::Dict{T,Index}
    lookup::Dict{Index,T}
    count::Base.RefValue{Index}
    TermBuilder{T}() where {T} = new{T}(Dict{T,Index}(), Dict{Index,T}(), Ref(zero(Index)))
end
Base.broadcastable(b::TermBuilder) = Ref(b)
function Base.push!(b::TermBuilder, x)
    haskey(b.insert, x) && return b.insert[x]
    index = (b.count[] += one(Index))
    b.insert[x] = index
    b.lookup[index] = x
    return index
end
Base.getindex(b::TermBuilder, index::Index) = b.lookup[index]


struct Term{T}
    tree::Tree
    builder::TermBuilder{T}
end
(b::TermBuilder)(ex) = Term(expr_to_tree(b, ex), b)
Base.convert(::Type{Expr}, t::Term) = term_to_expr(t)

Base.:(==)(s::Term, t::Term) = s.builder === t.builder && s.tree == t.tree
