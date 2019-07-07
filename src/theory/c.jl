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
    αβ = fixed(t.β, fixed(t.α, V))
    βα = fixed(t.α, fixed(t.β, V))

    if length(βα) > length(αβ)
        cβ = compile(t.β, V)
        cα = compile(t.α, fixed(t.β, V))
        return CMatcher(t.root, cβ, cα)
    else
        cα = compile(t.α, V)
        cβ = compile(t.β, fixed(t.α, V))
        return CMatcher(t.root, cα, cβ)
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
