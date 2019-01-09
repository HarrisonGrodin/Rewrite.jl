export Term
export is_branch, root, children


struct Term
    x
end

@inline is_branch(t::Term) = isa(t.x, Expr)
@inline root(t::Term)     = is_branch(t) ? t.x.head                 : t.x
@inline children(t::Term) = is_branch(t) ? convert.(Term, t.x.args) : Term[]

Base.convert(::Type{Term}, t::Term) = t
Base.convert(::Type{Term}, x) = Term(x)
Base.convert(::Type{Expr}, t::Term) = t.x

Base.:(==)(s::Term, t::Term) = s.x == t.x
Base.isequal(s::Term, t::Term) = isequal(s.x, t.x)

function Base.map(f, t::Term)
    isa(t.x, Expr) || return t

    expr = Expr(root(t))
    append!(expr.args, map(t -> (f(t)::Term).x, children(t)))
    convert(Term, expr)
end
