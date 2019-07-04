export FreeTerm

using Combinatorics


struct FreeTheory <: Theory end


struct FreeTerm <: AbstractTerm
    root::Σ
    args::Vector{Union{Variable,AbstractTerm}}
end
FreeTerm(root) = FreeTerm(root, Union{Variable,AbstractTerm}[])

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


@enum FreeKind VAR NODE ALIEN
struct FreeAux
    kind::FreeKind
    idx::UInt
    args::Vector{FreeAux}
end
FreeAux(kind, idx) = FreeAux(kind, idx, FreeAux[])
struct FreeMatcher <: AbstractMatcher
    m::FreeAux
    syms::Vector{Σ}
    vars::Vector{Variable}
    aliens::Vector{AbstractMatcher}
    ϕ::Vector{Int}
end

_Vm(aliens, V) = foldr(fixed, reverse(aliens); init=V)
function _find_context!(t::FreeTerm, vars, aliens)
    for arg ∈ t.args
        if isa(arg, Variable)
            push!(vars, arg)
        elseif isa(arg, FreeTerm)
            _find_context!(arg, vars, aliens)
        else
            push!(aliens, arg)
        end
    end

    return nothing
end
function _find_permutation(aliens, V)
    # TODO: improve efficiency using monotonicity
    best = V
    ϕ = eachindex(aliens)

    for ψ ∈ permutations(eachindex(aliens))
        Vm = _Vm(aliens[ψ], V)
        if length(Vm) > length(best)
            ϕ = ψ
            best = Vm
        end
    end

    return (best, ϕ)
end
function fixed(t::FreeTerm, V)
    vars = Set{Variable}()
    aliens = AbstractTerm[]
    _find_context!(t, vars, aliens)
    _find_permutation(aliens, vars)[1]
end

function _compile_free(t::FreeTerm, syms, vars, aliens)
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
            args[i] = _compile_free(arg, syms, vars, aliens)
        else
            push!(aliens, arg)
            args[i] = FreeAux(ALIEN, length(aliens), [])
        end
    end

    return FreeAux(NODE, node_idx, args)
end
function compile(t::FreeTerm, V)
    syms = Σ[]
    vars = Variable[]
    aliens = AbstractTerm[]
    m = _compile_free(t, syms, vars, aliens)

    V = V ∪ vars

    (_, ϕ) = _find_permutation(aliens, V)
    matchers = similar(aliens, AbstractMatcher)
    for i ∈ ϕ
        alien = aliens[i]
        matchers[i] = compile(alien, V)
        V = fixed(alien, V)
    end

    FreeMatcher(m, syms, vars, matchers, ϕ)
end


struct FreeSubproblem <: AbstractSubproblem
    subproblems
end

function match(A::FreeMatcher, t::FreeTerm)
    σ = Dict()
    aliens = similar(A.aliens, AbstractTerm)
    subproblems = similar(A.aliens, AbstractSubproblem)
    aliens_found = Ref(0)
    match_aux!(A.m, A, σ, aliens, aliens_found, t) || return nothing
    aliens_found[] == length(A.aliens) || return nothing

    for (i, j) ∈ enumerate(A.ϕ)
        matcher = A.aliens[j]
        alien = aliens[j]

        a_match = match(matcher, alien)
        a_match === nothing && return nothing

        compatible(σ, a_match.p) || return nothing
        merge!(σ, a_match.p)
        subproblems[i] = a_match.s
    end

    Matches(σ, FreeSubproblem((subproblems...,)))
end

function match_aux!(m, A, σ, aliens, aliens_found, t)
    if m.kind === VAR
        x = A.vars[m.idx]
        if haskey(σ, x)
            σ[x] == t || return false
        else
            σ[x] = t
        end
        return true
    end

    if m.kind === NODE
        isa(t, FreeTerm) || return false

        t.root === A.syms[m.idx] || return false
        for (arg, aux) ∈ zip(t.args, m.args)
            match_aux!(aux, A, σ, aliens, aliens_found, arg) || return false
        end
    else
        aliens[m.idx] = t
        aliens_found[] += 1
    end

    return true
end


Base.iterate(iter::Matches{FreeSubproblem}) = _aiterate(iter.p, iter.s.subproblems...)
Base.iterate(iter::Matches{FreeSubproblem}, st) = _aiterate1(iter.p, (iter.s.subproblems...,), st)
