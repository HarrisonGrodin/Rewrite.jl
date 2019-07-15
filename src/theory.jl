export Theory, @term, @theory, @rules


struct Theory
    name::Symbol
    d::Dict{Σ,AbstractTheory}
end
Base.show(io::IO, th::Theory) = print(io, th.name)


struct Term
    th::Theory
    t::Union{Variable,AbstractTerm}
end
Base.:(==)(s::Term, t::Term) = s.th == t.th && s.t == t.t
Base.hash(t::Term, h::UInt) = hash(t.t, hash(t.th, hash(Term, h)))
function Base.show(io::IO, t::Term)
    term_expr = convert(Expr, t.t)
    Base.show_call(io, :call, Symbol("@term"), [t.th.name, term_expr], 0)
end

function _to_theory(th::Theory, expr, strict)
    (root, args) = if isa(expr, Symbol)
        (expr, [])
    elseif isa(expr, Expr)
        expr.head === :call || throw(ArgumentError("invalid non-call Expr"))
        (expr.args[1], expr.args[2:end])
    elseif isa(expr, Term)
        expr.th == th || throw(ArgumentError("cannot combine different theories: $(expr.th) and $th"))
        return expr.t
    elseif isa(expr, Union{Variable,AbstractTerm})
        return expr
    else
        throw(ArgumentError("invalid expression: $(repr(expr))"))
    end

    root_theory = haskey(th.d, root) ? th.d[root] :
        strict ? throw(ArgumentError("$root undefined in theory")) : FreeTheory()

    for i ∈ eachindex(args)
        args[i] = _to_theory(th, args[i], strict)
    end

    term(root_theory, root, args)
end

(th::Theory)(expr; strict=false) = Term(th, _to_theory(th, expr, strict))

macro term(th, expr)
    :($(esc(th))($(Meta.quot(expr))))
end

macro theory(name, body)
    @assert isa(name, Symbol)
    @assert isa(body, Expr) && body.head === :block
    Base.remove_linenums!(body)

    for i ∈ eachindex(body.args)
        line = body.args[i]
        @assert line.head === :call
        line.args[2] = Meta.quot(line.args[2])
        body.args[i] = esc(line)
    end

    :($(esc(name)) = Theory($(Meta.quot(name)), Dict($(body.args...))))
end

function _rules_replace!(ex, vars)
    isa(ex, Symbol) && return get(vars, ex, ex)

    if isa(ex, Expr)
        for i ∈ eachindex(ex.args)
            ex.args[i] = _rules_replace!(ex.args[i], vars)
        end
    end
    return ex
end
function _clean(ex, th, vars)
    ex′ = Meta.quot(_rules_replace!(ex, vars))
    :($(esc(th))($ex′; strict=true))
end
macro rules(name, th, varnames, body)
    @assert isa(th, Symbol)
    @assert isa(name, Symbol)
    @assert isa(varnames, Expr) && varnames.head === :vect
    @assert all(isa(x, Symbol) for x ∈ varnames.args)
    @assert isa(body, Expr) && body.head === :block
    Base.remove_linenums!(body)

    vars = Dict(x => Variable() for x ∈ varnames.args)
    var_exprs = Expr(:block, (:($x = $v) for (x, v) ∈ vars)...)

    args = similar(body.args, Expr)
    for i ∈ eachindex(body.args)
        line = body.args[i]
        @assert line.head === :(:=)
        lhs, rhs = _clean.(line.args, Ref(th), Ref(vars))
        args[i] = :($lhs => replace($rhs))
    end

    let_expr = Expr(:let, var_exprs, :(Rewriter($(args...))))
    return :($(esc(name)) = $let_expr)
end


theory(t::Term) = theory(t.t)

_wrap_theory(th) = Base.Fix1(_wrap_theory, th)
_wrap_theory(th, d) = Dict(k => th(v) for (k, v) ∈ d)
function match(s::Term, t::Term)
    s.th == t.th || throw(ArgumentError("cannot matchterms from different theories: $(s.th) and $(t.th)"))
    LazyMap(_wrap_theory(s.th), match(s.t, t.t))
end

replace(t::Term) = Base.Fix1(replace, t.t)
Base.push!(rw::Rewriter, (p, b)::Pair{Term}) = push!(rw, p.t => b)
rewrite(rw, t::Term) = Term(t.th, rewrite(rw, t.t))
