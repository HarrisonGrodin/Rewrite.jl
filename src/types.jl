export Variable, TermSet, Term


const Index = UInt64


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
    pool::Vector{T}
    TermSet{T}() where {T} = new{T}(T[])
end
Base.broadcastable(ts::TermSet) = Ref(ts)
function Base.getindex(ts::TermSet, x::Node)
    x.kind === VARIABLE && return Variable(x.index)
    x.kind === CONSTANT && return ts.pool[x.index]
end


struct Term{T}
    term::Tree
    set::TermSet{T}
end
(ts::TermSet)(ex)  = Term(expr_to_term(ts, ex), ts)
Base.convert(::Type{Expr}, t::Term) = term_to_expr(t)

Base.:(==)(s::Term, t::Term) = s.set === t.set && convert(Expr, s) == convert(Expr, t)
