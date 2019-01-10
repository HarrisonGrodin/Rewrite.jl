export Term, @term
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


macro term(ex)
   :(Term($(_term(ex))))
end
function _term(ex)
    isa(ex, Expr) || return _unwrap_ex(ex)
    ex.head === :$ && return _unwrap_ex(ex.args[1])
    ex.head === :. && return _unwrap_ex(ex)
    return :(Expr($(Meta.quot(ex.head)), $(_term.(ex.args)...)))
end
_unwrap_ex(ex) = :(_unwrap($(esc(ex))))
_unwrap(t) = isa(t, Term) ? t.x : t


function _show_term(f::Function)
    # Inspired by: `show(::IO, ::Function)`
    ft = typeof(f)
    mt = ft.name.mt
    Base.is_exported_from_stdlib(mt.name, mt.module) && return mt.name
    return :($(nameof(mt.module)).$(mt.name))
end
function _show_term(ex::Expr)
    ex′ = Expr(ex.head)
    append!(ex′.args, _show_term.(ex.args))
    ex′
end
_show_term(x::Symbol) = Meta.quot(x)
_show_term(x) = x
function Base.show(io::IO, t::Term)
    macro_call = Expr(:macrocall, Symbol("@term"), nothing, _show_term(t.x))
    repr = sprint(show, macro_call)[9:end-1]
    print(io, "@term(", repr, ")")
end
