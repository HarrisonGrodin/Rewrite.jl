import Base: match

export Variable, match


const Σ = Symbol
>ₑ(a::Σ, b::Σ) = a > b


abstract type Theory end
abstract type AbstractTerm end
abstract type AbstractMatcher end
abstract type AbstractSubproblem end


mutable struct Variable end


const Substitution = Dict{Variable,AbstractTerm}

struct Matches{S<:AbstractSubproblem}
    p::Substitution
    s::S
end
Base.IteratorSize(::Type{<:Matches}) = Base.SizeUnknown()

struct Fail end
Base.iterate(::Fail) = nothing
Base.length(::Fail) = 0
const fail = Fail()

"""
    match(pattern::AbstractMatcher, term::AbstractTerm)

Match `term` against `pattern`, producing an iterator containing all matches.
"""
function match(p::AbstractMatcher, t::AbstractTerm)
    σ = Substitution()
    s = match!(σ, p, t)
    s === nothing && return fail
    Matches(σ, s)
end


struct EmptySubproblem <: AbstractSubproblem end
Base.iterate(m::Matches{EmptySubproblem}) = (m.p, nothing)
Base.iterate(::Matches{EmptySubproblem}, ::Any) = nothing

vars(x::Variable) = Set([x])
compile(x::Variable, V) = (x, push!(copy(V), x))
@inline function match!(σ, x::Variable, t::AbstractTerm)
    if haskey(σ, x)
        σ[x] == t || return nothing
    else
        σ[x] = t
    end
    return EmptySubproblem()
end

>ₜ(::Variable, ::AbstractTerm) = false
>ₜ(::AbstractTerm, ::Variable) = true
>ₜ(x::Variable, y::Variable) = objectid(x) > objectid(y)
