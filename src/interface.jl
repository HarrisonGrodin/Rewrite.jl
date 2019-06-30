import Base.match

export vars, match


const Σ = Symbol
>ₑ(a::Σ, b::Σ) = a > b


abstract type Theory end
abstract type AbstractTerm end
abstract type AbstractMatcher end
abstract type AbstractSubproblem end


"""
    vars(t::AbstractTerm) -> Set{Variable}

Produce the set of variables which appear as subterms of `t`.
"""
function vars end
vars(x::Variable) = Set([x])


"""
    s::AbstractTerm >ₜ t::AbstractTerm

Total ordering on terms.
"""
function >ₜ end

>ₜ(::Variable, ::AbstractTerm) = true
>ₜ(::AbstractTerm, ::Variable) = false
>ₜ(x::Variable, y::Variable) = objectid(x) > objectid(y)

function priority end
priority(::T) where {T<:AbstractTerm} = error("Priority undefined for: $T")
priority(t) = priority(typeof(t))
>ₜ(s::AbstractTerm, t::AbstractTerm) = priority(s) >ₜ priority(t)


"""
    compile(t::AbstractTerm [, V::Set{Variable} = Set()])

Compile `t` to a matcher, given that variables `V` will already be matched.
"""
function compile end
compile(t) = compile(t, Set{Variable}())
compile(x::Variable, V) = x


struct Matches{S<:AbstractSubproblem}
    p::Dict
    s::S
end
Base.IteratorSize(::Type{<:Matches}) = Base.SizeUnknown()

"""
    match(pattern::AbstractMatcher, term::AbstractTerm)

Match `term` against `pattern`, producing an iterator containing all matches if the process
succeeds and `nothing` otherwise.
"""
match(::AbstractMatcher, ::AbstractTerm) = nothing
match(p::AbstractTerm, s::AbstractTerm) = match(compile(p), s)
match(x::Variable, t::AbstractTerm) =
    Matches(Dict{Variable,AbstractTerm}(x => t), IdentitySubproblem())


struct IdentitySubproblem <: AbstractSubproblem end
Base.iterate(m::Matches{IdentitySubproblem}) = (m.p, nothing)
Base.iterate(::Matches{IdentitySubproblem}, ::Any) = nothing
