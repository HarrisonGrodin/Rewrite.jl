export FreeTheory


using Combinatorics


struct FreeTheory <: AbstractTheory end


struct FreeTerm <: AbstractTerm
    root::Σ
    args::Vector{Union{Variable,AbstractTerm}}
end
FreeTerm(root) = FreeTerm(root, Union{Variable,AbstractTerm}[])

term(::FreeTheory, root, args) = FreeTerm(root, args)
Base.convert(::Type{Expr}, t::FreeTerm) = Expr(:call, t.root, convert.(Expr, t.args)...)

theory(::Type{FreeTerm}) = FreeTheory()
priority(::Type{FreeTerm}) = 1000

vars(t::FreeTerm) = mapreduce(vars, ∪, t.args; init=Set{Variable}())

function Base.:(==)(a::FreeTerm, b::FreeTerm)
    a.root == b.root || return false

    for i ∈ eachindex(a.args)
        a.args[i] == b.args[i] || return false
    end

    return true
end

function (a::FreeTerm >ₜ b::FreeTerm)
    a.root == b.root || return a.root >ₑ b.root
    @assert length(a.args) == length(b.args)

    for (x, y) ∈ zip(a.args, b.args)
        x == y || return x >ₜ y
    end

    return false
end

function Base.hash(t::FreeTerm, h::UInt)
    init = hash(t.root, hash(FreeTerm, h))
    foldr(hash, t.args; init=init)
end

Base.map(f, t::FreeTerm) = FreeTerm(t.root, map(f, t.args))


@enum FreeKind VAR NODE ALIEN
struct FreeAux
    kind::FreeKind
    idx::UInt
    args::Vector{FreeAux}
end
struct FreeMatcher <: AbstractMatcher
    m::FreeAux
    syms::Vector{Σ}
    vars::Vector{Variable}
    matchers::Vector{AbstractMatcher}
    ϕ::Vector{Int}
end

function _build_free_context!(t::FreeTerm, syms, vars, aliens)
    args = similar(t.args, FreeAux)
    node_idx = findfirst(==(t.root), syms)
    node_idx === nothing && (push!(syms, t.root); node_idx = length(syms))

    for i ∈ eachindex(t.args)
        arg = t.args[i]
        if isa(arg, Variable)
            idx = findfirst(==(arg), vars)
            idx === nothing && (push!(vars, arg); idx = length(vars))
            args[i] = FreeAux(VAR, idx, [])
        elseif isa(arg, FreeTerm)
            args[i] = _build_free_context!(arg, syms, vars, aliens)
        else
            push!(aliens, arg)
            args[i] = FreeAux(ALIEN, length(aliens), [])
        end
    end

    return FreeAux(NODE, node_idx, args)
end

function _find_permutation(aliens, V)
    # TODO: improve efficiency using monotonicity
    matchers, V_best = many_matchers(aliens, V)
    ϕ = eachindex(aliens)

    for ψ ∈ permutations(eachindex(aliens))
        result, V′ = many_matchers(aliens[ψ], V)
        if length(V′) > length(V_best)
            (matchers, V_best, ϕ) = (result, num_fixed, ψ)
        end
    end

    return (matchers, V_best, ϕ)
end

function matcher(t::FreeTerm, V)
    syms = Σ[]
    vars = Variable[]
    aliens = AbstractTerm[]
    m = _build_free_context!(t, syms, vars, aliens)

    (matchers, V′, ϕ) = _find_permutation(aliens, V ∪ vars)
    return FreeMatcher(m, syms, vars, matchers, ϕ), V′
end


struct FreeSubproblem <: AbstractSubproblem
    subproblems::Vector{AbstractSubproblem}
end

function match!(σ, A::FreeMatcher, t::FreeTerm)
    if isempty(A.matchers)
        match_aux!(A.m, A, σ, nothing, t) === 0 || return nothing
        return EmptySubproblem()
    end

    aliens = similar(A.matchers, AbstractTerm)
    aliens_found = match_aux!(A.m, A, σ, aliens, t)
    aliens_found === length(A.matchers) || return nothing

    subproblems = similar(A.matchers, AbstractSubproblem)
    for i ∈ A.ϕ
        a_match = match!(σ, A.matchers[i], aliens[i])
        a_match === nothing && return nothing
        subproblems[i] = a_match
    end

    FreeSubproblem(subproblems)
end

function match_aux!(m, A, σ, aliens, t)
    if m.kind === VAR
        x = A.vars[m.idx]
        if haskey(σ, x)
            σ[x] == t || return -1
        else
            σ[x] = t
        end
        return 0
    end

    if m.kind === NODE
        isa(t, FreeTerm) || return -1

        t.root === A.syms[m.idx] || return -1
        length(t.args) === length(m.args) || return -1
        res = 0
        for (arg, aux) ∈ zip(t.args, m.args)
            res += match_aux!(aux, A, σ, aliens, arg)
        end
        return res
    else
        aliens[m.idx] = t
        return 1
    end
end

function compile(A::FreeMatcher, V)
    fn_name = gensym(:match!_free)
    V′ = V ∪ A.vars

    aliens = similar(A.matchers, AbstractTerm)
    subproblems = similar(A.matchers, AbstractSubproblem)

    vars_seen = [x ∈ V for x ∈ A.vars]
    recursive_matchers = _compile_free_aux(A.m, :t, aliens, A.syms, A.vars, vars_seen)

    alien_matches = []
    matcher_fns = []
    for i ∈ A.ϕ
        a_match = gensym(:a_match)
        fn, fn_expr = compile(A.matchers[i], V′)
        append!(matcher_fns, fn_expr.args)
        body = quote
            $a_match = $fn(σ, $aliens[$i])
            $a_match === nothing && return nothing
            $subproblems[$i] = $a_match
        end
        @assert body.head === :block
        append!(alien_matches, body.args)
    end

    subs_expr = isempty(subproblems) ? EmptySubproblem() :
                length(subproblems) == 1 ? :($subproblems[1]) : FreeSubproblem(subproblems)

    fn_name, quote
        $(matcher_fns...)
        function $fn_name(σ, t)
            $(recursive_matchers.args...)
            $(alien_matches...)
            $subs_expr
        end
    end
end
function _compile_free_aux(m, t, aliens, syms, vars, vars_seen)
    idx = m.idx

    if m.kind === VAR
        x = vars[idx]
        if vars_seen[idx]
            return quote
                σ[$x] == $t || return nothing
            end
        else
            vars_seen[idx] = true
            return quote
                σ[$x] = $t
            end
        end
    end

    if m.kind === NODE
        t′ = t
        t = gensym(:t)
        recs = [_compile_free_aux(arg, :($t.args[$i]), aliens, syms, vars, vars_seen)
                for (i, arg) ∈ enumerate(m.args)]
        recursive_calls = []
        for rec ∈ recs
            if rec.head === :block
                append!(recursive_calls, rec.args)
            else
                push!(recursive_calls, rec)
            end
        end

        return quote
            $t = $t′
            isa($t, $FreeTerm) || return
            $t.root == $(Meta.quot(syms[idx])) || return
            length($t.args) == $(length(m.args)) || return
            $(recursive_calls...)
        end
    else
        quote
            $aliens[$(m.idx)] = $t
        end
    end
end


Base.iterate(iter::Matches{FreeSubproblem}) = _aiterate(iter.p, iter.s.subproblems...)
Base.iterate(iter::Matches{FreeSubproblem}, st) = _aiterate1(iter.p, (iter.s.subproblems...,), st)

replace(p::FreeTerm, σ) = FreeTerm(p.root, Union{Variable,AbstractTerm}[replace(arg, σ) for arg ∈ p.args])


struct FreeRewriter <: AbstractRewriter
    rules::Dict{Σ,Vector{Pair{FreeMatcher,Any}}}
end

rewriter(::FreeTheory) = FreeRewriter(Dict{Σ,Vector{Pair{FreeMatcher,Any}}}())
function Base.push!(rw::FreeRewriter, (p, b)::Pair{FreeTerm})
    haskey(rw.rules, p.root) || (rw.rules[p.root] = Pair{FreeMatcher,Any}[])
    push!(rw.rules[p.root], matcher(p) => b)
    rw
end

function rewrite(rw::FreeRewriter, t::FreeTerm)
    haskey(rw.rules, t.root) || return nothing

    for (pattern, builder) ∈ rw.rules[t.root]
        next = iterate(match(pattern, t))
        next === nothing && continue
        σ = next[1]
        return builder(σ)::AbstractTerm
    end

    return nothing
end
