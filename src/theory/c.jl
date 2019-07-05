export CTerm


struct CTheory <: Theory end


struct CTerm <: AbstractTerm
    root::Σ
    α::Union{Variable,AbstractTerm}
    β::Union{Variable,AbstractTerm}
    CTerm(root, s, t) = s >ₜ t ? new(root, t, s) : new(root, s, t)
end

theory(::Type{CTerm}) = CTheory()
priority(::Type{CTerm}) = 20

vars(t::CTerm) = vars(t.α) ∪ vars(t.β)

Base.:(==)(a::CTerm, b::CTerm) = a.root == b.root && a.α == b.α && a.β == b.β

function (a::CTerm >ₜ b::CTerm)
    a.root == b.root || return a.root >ₑ b.root
    return a.α >ₜ b.α || (a.α == b.α && a.β >ₜ b.β)
end

Base.hash(t::CTerm, h::UInt) = hash(t.β, hash(t.α, hash(t.root, hash(CTerm, h))))


struct CMatcher <: AbstractMatcher
    root::Σ
    s::Union{Variable,AbstractMatcher}
    t::Union{Variable,AbstractMatcher}
end

function fixed(t::CTerm, V)
    vars(t.α) ⊆ V && return fixed(t.β, V)
    vars(t.β) ⊆ V && return fixed(t.α, V)

    isa(t.α, AbstractTerm) & isa(t.β, AbstractTerm) || return V
    theory(t.α) === theory(t.β) && return V

    αβ = fixed(t.β, fixed(t.α, V))
    βα = fixed(t.α, fixed(t.β, V))
    length(βα) > length(αβ) ? βα : αβ
end

function compile(t::CTerm, V)
    cα = compile(t.α, V)
    cβ = compile(t.β, V)
    return vars(t.β) ⊆ V ? CMatcher(t.root, cβ, cα) : CMatcher(t.root, cα, cβ)
end


struct CSubproblem <: AbstractSubproblem
    subproblems::Vector{Tuple{Substitution,Tuple{AbstractSubproblem,AbstractSubproblem}}}
end

@inline function _filter_nothing(a, b)
    subproblems = Tuple{Substitution,Tuple{AbstractSubproblem,AbstractSubproblem}}[]
    a === nothing || push!(subproblems, a)
    b === nothing || push!(subproblems, b)
    return subproblems
end
function _match_c(σ, s, t, α, β)
    subproblems = AbstractSubproblem[]
    σ′ = copy(σ)

    x1 = match!(σ′, s, α)
    x1 === nothing && return nothing

    x2 = match!(σ′, t, β)
    x2 === nothing && return nothing

    return (σ′, (x1.s, x2.s))
end
function match!(σ, A::CMatcher, t::CTerm)
    A.root == t.root || return nothing

    a = _match_c(σ, A.s, A.t, t.α, t.β)
    b = _match_c(σ, A.s, A.t, t.β, t.α)

    a === nothing && b === nothing && return nothing

    return CSubproblem(_filter_nothing(a, b))
end


function Base.iterate(iter::Matches{CSubproblem})
    i = 0
    next = nothing
    local P₁, problems

    while next === nothing
        i += 1
        i ≤ length(iter.s.subproblems) || return nothing
        (P₀, problems) = iter.s.subproblems[i]
        compatible(P₀, iter.p) || (i += 1; continue)
        P₁ = merge(P₀, iter.p)
        next = _aiterate(P₁, problems...)
    end

    (P, states) = next
    return (P, (i, P₁, problems, states))
end
function Base.iterate(iter::Matches{CSubproblem}, (i, P₁, problems, states))
    next = _aiterate1(P₁, problems, states)

    while next === nothing
        i += 1
        i ≤ length(iter.s.subproblems) || return nothing
        (P₀, problems) = iter.s.subproblems[i]
        compatible(P₀, iter.p) || (i += 1; continue)
        P₁ = merge(P₀, iter.p)
        next = _aiterate(P₁, problems...)
    end

    (P, states) = next
    return (P, (i, P₁, problems, states))
end
