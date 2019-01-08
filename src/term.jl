export Term
export is_branch, root, children


struct Term
    x
end

@inline _unwrap(t::Term) = t.x

@inline is_branch(t::Term) = isa(_unwrap(t), Expr)
@inline root(t::Term)     = is_branch(t) ? _unwrap(t).head                 : _unwrap(t)
@inline children(t::Term) = is_branch(t) ? convert.(Term, _unwrap(t).args) : Term[]

Base.convert(::Type{Term}, t::Term) = t
Base.convert(::Type{Term}, x) = Term(x)
Base.convert(::Type{Expr}, t::Term) = _unwrap(t)

Base.:(==)(s::Term, t::Term) = _unwrap(s) == _unwrap(t)
Base.isequal(s::Term, t::Term) = isequal(_unwrap(s), _unwrap(t))

function Base.map(f, t::Term)
    isa(_unwrap(t), Expr) || return t

    expr = Expr(root(t))
    append!(expr.args, map(_unwrap ∘ f, children(t)))
    convert(Term, expr)
end
