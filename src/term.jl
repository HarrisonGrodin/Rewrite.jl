export Term, @term
export isleaf, root, children


struct Term
    head::Any
    args::Vector{Term}
end
Term(head) = Term(head, Term[])

@inline isleaf(t::Term) = isempty(t.args)
@inline root(t::Term) = t.head
@inline children(t::Term) = t.args

Base.convert(::Type{Term}, t::Term) = t
Base.convert(::Type{Term}, ex::Expr) = Term(ex.head, collect(Term, ex.args))
Base.convert(::Type{Term}, x) = Term(x)
function Base.convert(::Type{Expr}, t::Term)
    isa(t.head, Symbol) || return t.head
    isempty(t.args)     && return t.head

    expr = Expr(t.head)
    append!(expr.args, convert.(Expr, t.args))
    return expr
end

Base.:(==)(s::Term, t::Term) = (s.head, s.args) == (t.head, t.args)
Base.isequal(s::Term, t::Term) = isequal((s.head, s.args), (t.head, t.args))

Base.eachindex(t::Term) = eachindex(t.args)
Base.firstindex(t::Term) = first(eachindex(t))
Base.lastindex(t::Term) = last(eachindex(t))

@inline function Base.getindex(t::Term, i)
    @boundscheck checkindex(Bool, eachindex(t), i) || throw(BoundsError(t, i))
    return t.args[i]
end
Base.getindex(t::Term, inds...) = foldl(getindex, inds; init=t)

Base.hash(t::Term, h::UInt) = hash((t.head, t.args), hash(Term, h))

Base.map(f, t::Term) = Term(t.head, map(f, t.args))
_replace(σ) = Base.Fix2(replace, σ)
Base.replace(t::Term, σ::AbstractDict) = haskey(σ, t) ? σ[t] : map(_replace(σ), t)


macro term(ex)
    _term(ex)
end
function _term(ex)
    isa(ex, Expr)  || return _unwrap_ex(ex)
    ex.head === :$ && return _unwrap_ex(ex.args[1])
    ex.head === :. && return _unwrap_ex(ex)
    return :(Term($(Meta.quot(ex.head)), Term[$(_term.(ex.args)...)]))
end
_unwrap_ex(ex) = :(unwrap($(esc(ex))))
unwrap(t) = convert(Term, t)


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
function Base.show(io::IO, t::Term)
    show_expr = _show(convert(Expr, t))
    Base.show_call(io, :call, Symbol("@term"), [show_expr], 0)
end
