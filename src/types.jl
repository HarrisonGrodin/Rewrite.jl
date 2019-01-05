export Variable, TermSet, Term


const VARIABLE_COUNTER = Ref{UInt64}(0)
struct Variable{V}
    id::UInt64
    data::V

    Variable{T}(data) where {T} = new{T}((VARIABLE_COUNTER[] += 1), data)
end
Variable(x::T) where {T} = Variable{T}(x)
Base.:(==)(x::Variable, y::Variable) = x.id === y.id


struct TermSet{V,T}
    pool::Vector{T}
    vars::Vector{Variable{V}}

    TermSet{V,T}() where {V,T} = new(T[], Variable{V}[])
end
Base.broadcastable(ts::TermSet) = Ref(ts)
function Base.getindex(ts::TermSet, x::Node)
    x.kind === VARIABLE && return ts.vars[x.index]
    x.kind === CONSTANT && return ts.pool[x.index]
    throw(ArgumentError("invalid kind: $(x.kind)"))
end


struct Term{V,T}
    term::TermTree
    set::TermSet{V,T}
end
(ts::TermSet)(ex)  = Term(expr_to_term(ts, ex), ts)
Base.Expr(t::Term) = term_to_expr(t)

Base.:(==)(s::Term, t::Term) = s.set === t.set && Expr(s) == Expr(t)
