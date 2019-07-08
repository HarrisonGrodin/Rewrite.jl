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
match(p::AbstractTerm, t::AbstractTerm) = match(compile(p), t)


struct EmptySubproblem <: AbstractSubproblem end
Base.iterate(m::Matches{EmptySubproblem}) = (m.p, nothing)
Base.iterate(::Matches{EmptySubproblem}, ::Any) = nothing
