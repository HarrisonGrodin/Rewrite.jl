export compile, replace, rewrite


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
    compile(t::AbstractTerm, V::Set{Variable}) -> Tuple{AbstractMatcher,Set{Variable}}

Compile `t` to a matcher, given that variables `V` will already be matched. Produce a set
of variables which are guaranteed to be fixed during matching.
"""
function compile end

"""
    compile(t::AbstractTerm) -> AbstractMatcher

Compile `t` to a matcher.
"""
compile(t) = compile(t, Set{Variable}())[1]

"""
    match!(σ, pattern::AbstractMatcher, term::AbstractTerm) -> Union{AbstractSubproblem,Nothing}

Match `term` against `pattern` given the partial substitution `σ`, mutating `σ` and
producing a subproblem to solve or producing `nothing` if a match is impossible.

!!! note

    Unless `pattern` and `term` are derived from the same theory, `match!` should
    necessarily produce `nothing`.
"""
match!(::Any, ::AbstractMatcher, ::AbstractTerm) = nothing

"""
    replace(pattern::AbstractTerm, σ::Substitution) -> AbstractTerm

Replace each variable subterm `x` of `pattern` with `σ[x]`.
"""
replace(pattern::AbstractTerm, σ::Substitution)

"""
    rewriter(t::Theory) -> AbstractRewriter

Produce a fresh rewriter for theory `t`.
"""
function rewriter end

"""
    rewrite(rw::AbstractRewriter, t::AbstractTerm) -> Union{AbstractTerm,Nothing}

Rewrite `t` using `rw`, producing `nothing` if the process fails.
"""
function rewrite end
