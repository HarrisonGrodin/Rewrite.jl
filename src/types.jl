export Variable, TermBuilder, Term


const Index = UInt32


@enum Kind::UInt8 VARIABLE CONSTANT
struct Leaf
    kind::Kind
    index::Index
end

struct Branch
    head::Symbol
    args::Vector{Union{Leaf, Branch}}
end
Base.:(==)(s::Branch, t::Branch) = (s.head, s.args) == (t.head, t.args)

const Tree = Union{Leaf, Branch}


const VARIABLE_COUNTER = Ref{Index}(0)
struct Variable
    id::Index
end
Variable() = Variable(VARIABLE_COUNTER[] += 1)


struct TermBuilder{T}
    insert::Dict{T,Index}
    lookup::Dict{Index,T}
    count::Base.RefValue{Index}
    TermBuilder{T}() where {T} = new{T}(Dict{T,Index}(), Dict{Index,T}(), Ref(zero(Index)))
end
Base.broadcastable(b::TermBuilder) = Ref(b)
function Base.push!(b::TermBuilder, x)
    haskey(b.insert, x) && return Leaf(CONSTANT, b.insert[x])
    index = (b.count[] += 1)
    b.insert[x] = index
    b.lookup[index] = x
    Leaf(CONSTANT, index)
end


struct Term{T}
    tree::Tree
    builder::TermBuilder{T}
end
(b::TermBuilder)(ex) = Term(expr_to_tree(b, ex), b)
Base.convert(::Type{Expr}, t::Term) = term_to_expr(t)

Base.:(==)(s::Term, t::Term) = s.builder === t.builder && convert(Expr, s) == convert(Expr, t)
