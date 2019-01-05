export Variable, TermSet, Term


const VARIABLE_COUNTER = Ref{UInt64}(0)
struct Variable
    id::UInt64
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
    term::TermTree
    set::TermSet{T}
end
(ts::TermSet)(ex)  = Term(expr_to_term(ts, ex), ts)
Base.Expr(t::Term) = term_to_expr(t)

Base.:(==)(s::Term, t::Term) = s.set === t.set && Expr(s) == Expr(t)
