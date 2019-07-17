"""
    term(t::AbstractTheory, root::Σ, args::Vector{AbstractTerm}) -> AbstractTerm

Produce a term in theory `t` with root `root` and arguments `args`. If an unexpected input
is provided, raise an exception.
"""
function term end

"""
    theory(T::Type{<:AbstractTerm}) -> AbstractTheory

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
    match!(σ, pattern::AbstractMatcher, term::AbstractTerm) -> Union{AbstractSubproblem,Nothing}

Match `term` against `pattern` given the partial substitution `σ`, mutating `σ` and
producing a subproblem to solve or producing `nothing` if a match is impossible.

!!! note

    Unless `pattern` and `term` are derived from the same theory, `match!` should
    necessarily produce `nothing`.
"""
match!(::Any, ::AbstractMatcher, ::AbstractTerm) = nothing

"""
    map(f, t::AbstractTerm) -> AbstractTerm

Call `f` on each subterm of `t`.
"""
Base.map(f, t::AbstractTerm)

"""
    rewriter(t::AbstractTheory) -> AbstractRewriter

Produce a fresh rewriter for theory `t`.
"""
function rewriter end

"""
    rewrite(rw::AbstractRewriter, t::AbstractTerm) -> AbstractTerm

Rewrite `t` using `rw`, producing `nothing` if the process fails.
"""
function rewrite end
