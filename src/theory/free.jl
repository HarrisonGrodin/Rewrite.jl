export FreeTerm


struct FreeTheory <: Theory end


struct FreeTerm <: AbstractTerm
    root::Σ
    args::Vector{Union{Variable,AbstractTerm}}
end
FreeTerm(root) = FreeTerm(root, Union{Variable,AbstractTerm}[])

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

    ϕ = eachindex(aliens)  # TODO: find permutation
    matchers = map(a -> compile(a, V), aliens)  # TODO: compile with correct sub-V

    FreeMatcher(m, syms, vars, matchers[ϕ])
end


struct FreeSubproblem <: AbstractSubproblem
    subproblems
end

function match(A::FreeMatcher, t::FreeTerm)
    sigma = Dict()
    matchers = AbstractSubproblem[]
    res = match_aux!(A.m, A, sigma, matchers, t)
    return res ? Matches(sigma, FreeSubproblem((matchers...,))) : nothing
end

function match_aux!(m, A, σ, matchers, t)
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
            match_aux!(aux, A, σ, matchers, arg) || return false
        end
    else
        alien_match = match(A.aliens[m.idx], t)
        alien_match === nothing && return false
        (P, S) = (alien_match.p, alien_match.s)

        compatible(σ, P) || return false
        merge!(σ, P)

        push!(matchers, S)
    end

    return true
end


Base.iterate(iter::Matches{FreeSubproblem}) = _aiterate(iter.p, iter.s.subproblems...)
Base.iterate(iter::Matches{FreeSubproblem}, st) = _aiterate1(iter.p, (iter.s.subproblems...,), st)
