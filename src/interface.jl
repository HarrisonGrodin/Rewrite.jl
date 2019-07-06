import Base.match

export vars, compile, match


const Σ = Symbol
>ₑ(a::Σ, b::Σ) = a > b


abstract type Theory end
abstract type AbstractTerm end
abstract type AbstractMatcher end
abstract type AbstractSubproblem end


"""
    theory(T::Type{<:AbstractTerm}) -> Theory

Produce the theory which contains type `T`.
"""
function theory end
theory(t::T) where {T<:AbstractTerm} = theory(T)

"""
    vars(t::AbstractTerm) -> Set{Variable}

Produce the set of variables which appear as subterms of `t`.
"""
function vars end


"""
    priority(::Type{<:AbstractTerm}) -> Int

Priority of a term type, used to produce a total ordering over terms.

!!! note

    The `priority` function must be injective; in other words, every type must map to a
    distinct priority.
"""
function priority end
priority(t::T) where {T<:AbstractTerm} = priority(T)

"""
    s::AbstractTerm >ₜ t::AbstractTerm -> Bool

Total ordering on terms.
"""
function >ₜ end
>ₜ(s::AbstractTerm, t::AbstractTerm) = priority(s) > priority(t)


"""
    fixed(pattern::AbstractTerm, V::Set{Variable}) -> Set{Variable}

Given that all variables in `V` are bound, produce the set of variables which must be
bound after matching a term against `pattern`.

!!! note

    The `fixed` function should adhere to the following monotonicity property.
    ```math
        fixed(t, V₁) ∪ fixed(t, V₂) ⊆ fixed(t, V₁ ∪ V₂)
    ```
"""
function fixed end

"""
    compile(t::AbstractTerm [, V::Set{Variable} = Set()]) -> AbstractMatcher

Compile `t` to a matcher, given that variables `V` will already be matched.
"""
function compile end
compile(t) = compile(t, Set{Variable}())


const Substitution = Dict{Variable,AbstractTerm}
struct Matches{S<:AbstractSubproblem}
    p::Substitution
    s::S
end
Base.IteratorSize(::Type{<:Matches}) = Base.SizeUnknown()

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

"""
    match!(σ, pattern::AbstractMatcher, term::AbstractTerm) -> AbstractSubproblem

Match `term` against `pattern` given the partial substitution `σ`, mutating `σ` and
producing a subproblem to solve or producing `nothing` if a match is impossible.
"""
match!(::Any, ::AbstractMatcher, ::AbstractTerm) = nothing
