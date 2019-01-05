export Variable, TermSet, Term


const Index = UInt32


@enum Kind::UInt8 VARIABLE CONSTANT
struct Node
    kind::Kind
    index::Index
end

struct Tree
    head::Symbol
    args::Vector{Union{Node, Tree}}
end


const VARIABLE_COUNTER = Ref{Index}(0)
struct Variable
    id::Index
end
Variable() = Variable(VARIABLE_COUNTER[] += 1)


struct TermSet{T}
    insert::Dict{T,Index}
    lookup::Dict{Index,T}
    count::Ref{Index}
    TermSet{T}() where {T} = new{T}(Dict{T,Index}(), Dict{Index,T}(), Ref{Index}(0))
end
Base.broadcastable(ts::TermSet) = Ref(ts)
function Base.getindex(ts::TermSet, x::Node)
    x.kind === VARIABLE && return Variable(x.index)
    x.kind === CONSTANT && return ts.lookup[x.index]
end
function Base.push!(ts::TermSet, x)
    haskey(ts.insert, x) && return Node(CONSTANT, ts.insert[x])
    index = (ts.count[] += 1)
    ts.insert[x] = index
    ts.lookup[index] = x
    Node(CONSTANT, index)
end


struct Term{T}
    tree::Tree
    set::TermSet{T}
end
(ts::TermSet)(ex) = Term(expr_to_term(ts, ex), ts)
Base.convert(::Type{Expr}, t::Term) = term_to_expr(t)

Base.:(==)(s::Term, t::Term) = s.set === t.set && convert(Expr, s) == convert(Expr, t)
