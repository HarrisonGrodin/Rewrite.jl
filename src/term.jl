export Term, @term
export isleaf, root, children


struct Term
    x
end

@inline isleaf(t::Term) = !isa(t.x, Expr)
@inline root(t::Term) = isleaf(t) ? t.x : t.x.head
@inline children(t::Term) = [t[i] for i ∈ eachindex(t)]

Base.convert(::Type{Term}, t::Term) = t
Base.convert(::Type{Term}, x) = Term(x)
Base.convert(::Type{Expr}, t::Term) = t.x

Base.:(==)(s::Term, t::Term) = s.x == t.x
Base.isequal(s::Term, t::Term) = isequal(s.x, t.x)

Base.eltype(::Type{Term}) = Term
Base.eachindex(t::Term) = isleaf(t) ? Base.OneTo(0) : eachindex(t.x.args)
Base.firstindex(t::Term) = first(eachindex(t))
Base.lastindex(t::Term) = last(eachindex(t))
Base.length(t::Term) = length(eachindex(t))

@inline function Base.getindex(t::Term, i)
    @boundscheck checkindex(Bool, eachindex(t), i) || throw(BoundsError(t, i))
    return convert(Term, t.x.args[i])
end
Base.getindex(t::Term, inds...) = foldl(getindex, inds; init=t)

function _iter(t::Term, next)
    next === nothing && return
    i, state = next
    return (t[i], state)
end
Base.iterate(t::Term) = _iter(t, iterate(eachindex(t)))
Base.iterate(t::Term, state) = _iter(t, iterate(eachindex(t), state))

function Base.map(f, t::Term)
    isa(t.x, Expr) || return t

    expr = Expr(root(t))
    append!(expr.args, map(_unwrap ∘ f, children(t)))
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
