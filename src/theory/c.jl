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
    subproblems
end

@inline _filter_nothing() = ()
@inline _filter_nothing(::Nothing, xs...) = _filter_nothing(xs...)
@inline _filter_nothing(x, xs...) = (x, _filter_nothing(xs...)...)
function _match_c(s, t, α, β)
    subproblems = AbstractSubproblem[]

    x1 = match(s, α)
    x1 === nothing && return nothing

    x2 = match(t, β)
    x2 === nothing && return nothing

    compatible(x1.p, x2.p) || return nothing
    p = x1.p
    merge!(p, x2.p)

    return (p, (x1.s, x2.s))
end
function match(A::CMatcher, t::CTerm)
    A.root == t.root || return nothing

    a = _match_c(A.s, A.t, t.α, t.β)
    b = _match_c(A.s, A.t, t.β, t.α)

    a === nothing && b === nothing && return nothing

    σ = Dict()
    return Matches(σ, CSubproblem(_filter_nothing(a, b)))
end


function Base.iterate(iter::Matches{CSubproblem})
    i = 0
    next = nothing
    local P₁, problems

    while next === nothing
        i += 1
        i ≤ length(iter.s.subproblems) || return nothing
        (P₀, problems) = iter.s.subproblems[i]
        P₁ = P₀ ⊔ iter.p
        P₁ === nothing && (i += 1; continue)
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
        P₁ = P₀ ⊔ iter.p
        P₁ === nothing && (i += 1; continue)
        next = _aiterate(P₁, problems...)
    end

    (P, states) = next
    return (P, (i, P₁, problems, states))
end
