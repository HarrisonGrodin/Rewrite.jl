export CTerm


struct CTheory <: AbstractTheory end


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

Base.map(f, t::CTerm) = CTerm(t.root, f(t.α), f(t.β))


struct CMatcher <: AbstractMatcher
    root::Σ
    s::Union{Variable,AbstractMatcher}
    t::Union{Variable,AbstractMatcher}
end

function compile(t::CTerm, V)
    if isa(t.α, Variable) | isa(t.β, Variable) || theory(t.α) === theory(t.β)
        (cα, _) = compile(t.α, V)
        (cβ, _) = compile(t.β, V)
        return CMatcher(t.root, cα, cβ), V
    end

    (αβ, V1) = compile_many([t.α, t.β], V)
    (βα, V2) = compile_many([t.β, t.α], V)

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
    push!(rw.rules[p.root], compile(p) => b)
    rw
end

function rewrite(rw::CRewriter, t::CTerm)
    haskey(rw.rules, t.root) || return nothing

    for (pattern, builder) ∈ rw.rules[t.root]
        next = iterate(match(pattern, t))
        next === nothing && continue
        σ = next[1]
        return builder(σ)::AbstractTerm
    end

    return nothing
end
