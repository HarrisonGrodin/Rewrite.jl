export Term, @term
export isleaf, root, children


struct Term
    x
end

@inline isleaf(t::Term) = !isa(t.x, Expr)
@inline root(t::Term) = isleaf(t) ? t.x : t.x.head
@inline children(t::Term) = [t[i] for i ∈ eachindex(t)]

function Base.getindex(t::Term, i)
    @boundscheck isleaf(t) && throw(BoundsError(t, i))
    @boundscheck checkbounds(Bool, t.x.args, i) || throw(BoundsError(t, i))
    return convert(Term, t.x.args[i])
end
Base.getindex(t::Term, inds...) = foldl(getindex, inds; init=t)
Base.eachindex(t::Term) = isleaf(t) ? Base.OneTo(0) : eachindex(t.x.args)

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
_unwrap(t) = convert(Term, t).x


function _show(f::Function)
    # Inspired by: `show(::IO, ::Function)`
    ft = typeof(f)
    mt = ft.name.mt
    Base.is_exported_from_stdlib(mt.name, mt.module) && return mt.name
    return :($(nameof(mt.module)).$(mt.name))
end
function _show(ex::Expr)
    ex′ = Expr(ex.head)
    append!(ex′.args, _show.(ex.args))
    ex′
end
_show(x::Symbol) = Meta.quot(x)
_show(x) = x
Base.show(io::IO, t::Term) = Base.show_call(io, :call, Symbol("@term"), [_show(t.x)], 0)
