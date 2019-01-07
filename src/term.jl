export Variable, Term


mutable struct Variable end
Base.promote_rule(::Type{Variable}, T::Type) = Union{Variable, T}
Base.promote_rule(::Type{Variable}, ::Type{Any}) = Any


struct Term{T}
    head::T
    args::Vector{Term{T}}
end
Term(head::T) where {T} = Term{T}(head, T[])
Term(head::T, args::Vector{Term{U}}) where {T,U} = Term{promote_type(T,U)}(head, args)

Base.:(==)(s::Term, t::Term) = (s.head, s.args) == (t.head, t.args)

Base.convert(::Type{Term{T}}, ex) where {T} = expr_to_term(T, ex)
Base.convert(::Type{Term{T}}, t::Term) where {T} = Term{T}(t.head, t.args)

Base.convert(::Type{Expr}, t::Term) = term_to_expr(t)

Base.promote_rule(::Type{Term{S}}, ::Type{Term{T}}) where {S,T} = Term{promote_type(S,T)}
