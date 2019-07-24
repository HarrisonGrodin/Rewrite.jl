export CTheory


struct CTheory <: AbstractTheory end


struct CTerm <: AbstractTerm
    root::Σ
    α::Union{Variable,AbstractTerm}
    β::Union{Variable,AbstractTerm}
    CTerm(root, s, t) = s >ₜ t ? new(root, t, s) : new(root, s, t)
end

function term(::CTheory, root, args)
    length(args) == 2 || throw(ArgumentError("invalid commutative term: expected 2 arguments, got $(length(args))"))
    CTerm(root, args[1], args[2])
end
Base.convert(::Type{Expr}, t::CTerm) = Expr(:call, t.root, convert(Expr, t.α), convert(Expr, t.β))

theory(::Type{CTerm}) = CTheory()
priority(::Type{CTerm}) = 20

vars(t::CTerm) = vars(t.α) ∪ vars(t.β)

Base.:(==)(a::CTerm, b::CTerm) = a.root == b.root && a.α == b.α && a.β == b.β

function (a::CTerm >ₜ b::CTerm)
    a.root == b.root || return a.root >ₑ b.root
    return a.α >ₜ b.α || (a.α == b.α && a.β >ₜ b.β)
end

Base.hash(t::CTerm, h::UInt) = hash(t.β, hash(t.α, hash(t.root, hash(CTerm, h))))

Base.map(f, t::CTerm) = CTerm(t.root, f(t.α), f(t.β))


struct CMatcher <: AbstractMatcher
    root::Σ
    s::Union{Variable,AbstractMatcher}
    t::Union{Variable,AbstractMatcher}
end

function matcher(t::CTerm, V)
    if isa(t.α, Variable) | isa(t.β, Variable) || theory(t.α) === theory(t.β)
        (cα, _) = matcher(t.α, V)
        (cβ, _) = matcher(t.β, V)
        return CMatcher(t.root, cα, cβ), V
    end

    (αβ, V1) = many_matchers([t.α, t.β], V)
    (βα, V2) = many_matchers([t.β, t.α], V)

    if length(V2) > length(V1)
        return CMatcher(t.root, βα[1], βα[2]), V2
    else
        return CMatcher(t.root, αβ[1], αβ[2]), V1
    end
end


struct CSubproblem <: AbstractSubproblem
    subproblems::Vector{Tuple{Substitution,Tuple{AbstractSubproblem,AbstractSubproblem}}}
end

function _match_c!(subproblems, σ, s, t, α, β)
    σ′ = copy(σ)

    x1 = match!(σ′, s, α)
    x1 === nothing && return

    x2 = match!(σ′, t, β)
    x2 === nothing && return

    push!(subproblems, (σ′, (x1, x2)))

    nothing
end
function match!(σ, A::CMatcher, t::CTerm)
    A.root == t.root || return nothing

    subproblems = Tuple{Substitution,Tuple{AbstractSubproblem,AbstractSubproblem}}[]

    _match_c!(subproblems, σ, A.s, A.t, t.α, t.β)
    _match_c!(subproblems, σ, A.s, A.t, t.β, t.α)

    isempty(subproblems) && return nothing

    return CSubproblem(subproblems)
end

function compile(A::CMatcher, V)
    fn_name = gensym(:match!_c)

    subproblems = gensym(:subproblems)
    len = gensym(:len)

    cs, csf = compile(A.s, V)
    ct, ctf = compile(A.t, V)

    return fn_name, quote
        $(csf.args...)
        $(ctf.args...)
        function $fn_name(σ, t)
            isa(t, $CTerm) || return
            t.root == $(Meta.quot(A.root)) || return

            $subproblems = $(Tuple{Substitution,Tuple{AbstractSubproblem,AbstractSubproblem}})[]

            $(_compile_expr_c(subproblems, V, cs, ct))
            $(_compile_expr_c(subproblems, V, ct, cs))

            $len = $length($subproblems)
            $len == 0 && return
            $CSubproblem($subproblems)
        end
    end
end
function _compile_expr_c(subproblems, V, cs, ct)
    σ′ = gensym(:σ′)

    quote
        $σ′ = copy(σ)

        x1 = $ct($σ′, t.α)
        if x1 !== nothing
            x2 = $cs($σ′, t.β)
            if x2 !== nothing
                push!($subproblems, ($σ′, (x1, x2)))
            end
        end
    end
end


function _iterate_c_aux(p, P₀, problems, i)
    compatible(P₀, p) || return nothing
    P₁ = merge(P₀, p)
    next = _aiterate(P₁, problems...)
    next === nothing && return nothing
    (P, states) = next
    return (P, (i, P₁, states))
end
function Base.iterate(iter::Matches{CSubproblem})
    i = 1

    while i ≤ length(iter.s.subproblems)
        (P₀, problems) = iter.s.subproblems[i]
        res = _iterate_c_aux(iter.p, P₀, problems, i)
        res === nothing && (i += 1; continue)
        return res
    end

    return nothing
end

function Base.iterate(iter::Matches{CSubproblem}, (i, P₁, states))
    next = _aiterate1(P₁, iter.s.subproblems[i][2], states)

    while next === nothing
        i += 1
        i ≤ length(iter.s.subproblems) || return nothing
        (P₀, problems) = iter.s.subproblems[i]
        compatible(P₀, iter.p) || continue
        P₁ = merge(P₀, iter.p)
        next = _aiterate(P₁, problems...)
    end

    (P, states) = next
    return (P, (i, P₁, states))
end


replace(p::CTerm, σ) = CTerm(p.root, replace(p.α, σ), replace(p.β, σ))


struct CRewriter <: AbstractRewriter
    rules::Dict{Σ,Vector{Pair{CMatcher,Any}}}
end

rewriter(::CTheory) = CRewriter(Dict{Σ,Vector{Pair{CMatcher,Any}}}())
function Base.push!(rw::CRewriter, (p, b)::Pair{CTerm})
    haskey(rw.rules, p.root) || (rw.rules[p.root] = Pair{CMatcher,Any}[])
    push!(rw.rules[p.root], matcher(p) => b)
    rw
end

function compile(rw::CRewriter)
    fn_name = gensym(:rewrite_c)

    matcher_exprs = Expr[]

    rules = Dict()
    for (root, matchers) ∈ rw.rules
        rules[root] = []
        for (p, b) ∈ matchers
            fn, expr = compile(p)
            push!(matcher_exprs, expr)
            push!(rules[root], fn => b)
        end
    end

    index = gensym(:rewrite_c_map)

    fn_name, quote
        $(matcher_exprs...)
        $index = Dict($((
            :($(Meta.quot(root)) => $(:([$((:($fn => $b) for (fn, b) ∈ rs)...)])))
            for (root, rs) ∈ rules
        )...))
        function $fn_name(t)
            $haskey($rules, t.root) || return

            σ = $Substitution()

            for (match_fn, builder) ∈ $index[t.root]
                m = match_fn(σ, t)
                m === nothing && continue
                next = iterate($Matches(σ, m))
                next === nothing && continue
                σ = next[1]
                return builder(σ)::$AbstractTerm
            end

            return
        end
    end
end
