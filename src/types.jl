export Variable, Term


mutable struct Variable end


struct Node{T}
    head::T
    args::Vector{Union{Node{T}, Variable}}
end
Base.:(==)(s::Node, t::Node) = (s.head, s.args) == (t.head, t.args)

const Tree{T} = Union{Node{T}, Variable}

struct Term{T}
    tree::Tree{T}
end
Base.convert(::Type{Term{T}}, ex) where {T} = Term{T}(expr_to_tree(T, ex))
Base.convert(::Type{Term{T}}, t::Term{T}) where {T} = t
Base.convert(::Type{Expr}, t::Term) = term_to_expr(t)
Base.:(==)(s::Term, t::Term) = s.tree == t.tree
