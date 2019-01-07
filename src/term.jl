export Variable, Term


mutable struct Variable end


struct Term{T}
    head::T
    args::Vector{Term{T}}
end

Base.:(==)(s::Term, t::Term) = (s.head, s.args) == (t.head, t.args)

Base.convert(::Type{Term{T}}, ex) where {T} = expr_to_term(T, ex)
Base.convert(::Type{Term{T}}, t::Term) where {T} = Term{T}(t.head, t.args)

Base.convert(::Type{Expr}, t::Term) = term_to_expr(t)
