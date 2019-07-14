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
    matchers, V_best = compile_many(aliens, V)
    ϕ = eachindex(aliens)

    for ψ ∈ permutations(eachindex(aliens))
        result, V′ = compile_many(aliens[ψ], V)
        if length(V′) > length(V_best)
            (matchers, V_best, ϕ) = (result, num_fixed, ψ)
        end
    end

    return (matchers, V_best, ϕ)
end

function compile(t::FreeTerm, V)
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


Base.iterate(iter::Matches{FreeSubproblem}) = _aiterate(iter.p, iter.s.subproblems...)
Base.iterate(iter::Matches{FreeSubproblem}, st) = _aiterate1(iter.p, (iter.s.subproblems...,), st)

replace(p::FreeTerm, σ) = FreeTerm(p.root, Union{Variable,AbstractTerm}[replace(arg, σ) for arg ∈ p.args])


struct FreeRewriter <: AbstractRewriter
    rules::Dict{Σ,Vector{Pair{FreeMatcher,Any}}}
end

rewriter(::FreeTheory) = FreeRewriter(Dict{Σ,Vector{Pair{FreeMatcher,Any}}}())
function Base.push!(rw::FreeRewriter, (p, b)::Pair{FreeTerm})
    haskey(rw.rules, p.root) || (rw.rules[p.root] = Pair{FreeMatcher,Any}[])
    push!(rw.rules[p.root], compile(p) => b)
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
