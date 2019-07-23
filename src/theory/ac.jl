export ACTheory

using Combinatorics
using DataStructures


struct ACTheory <: AbstractTheory end


struct ACTerm <: AbstractTerm
    root::Σ
    args::OrderedDict{Union{Variable,AbstractTerm},UInt}
    ACTerm(root, args) = new(root, sort(args, lt=(>ₜ), rev=true))
end

function term(::ACTheory, root, args)
    @assert !isempty(args)
    length(args) == 1 && return first(args)

    dict = OrderedDict{Union{Variable,AbstractTerm},UInt}()
    for arg ∈ args
        if isa(arg, ACTerm) && arg.root == root
            merge!(+, dict, arg.args)
        else
            dict[arg] = get(dict, arg, 0) + 1
        end
    end
    return ACTerm(root, dict)
end

_lt_pair_term(a, b) = b.first >ₜ a.first
function Base.convert(::Type{Expr}, t::ACTerm)
    targs = sort(collect(t.args), lt=_lt_pair_term)
    ex = Expr(:call, t.root)

    for (s, k) ∈ targs
        append!(ex.args, fill(convert(Expr, s), k))
    end

    ex
end

theory(::Type{ACTerm}) = ACTheory()
priority(::Type{ACTerm}) = 20

vars(t::ACTerm) = mapreduce(vars, ∪, keys(t.args); init=Set{Variable}())

Base.:(==)(a::ACTerm, b::ACTerm) = a.root == b.root && a.args == b.args

function (a::ACTerm >ₜ b::ACTerm)
    a.root == b.root || return a.root >ₑ b.root
    length(a.args) == length(b.args) || return length(a.args) > length(b.args)

    for ((p, i), (q, j)) ∈ zip(a.args, b.args)
        i == j || return i > j
        p == q || return p >ₜ q
    end

    return false
end

Base.hash(t::ACTerm, h::UInt) = hash(t.args, hash(t.root, hash(ACTerm, h)))

function Base.map(f, p::ACTerm)
    dict = OrderedDict{Union{Variable,AbstractTerm},UInt}()

    for (t, k) ∈ p.args
        t′ = f(t)
        if isa(t′, ACTerm) && t′.root == p.root
            for (u, i) ∈ t′.args
                dict[u] = get(dict, u, 0) + i*k
            end
        else
            dict[t′] = get(dict, t′, 0) + k
        end
    end

    return ACTerm(p.root, dict)
end


struct ACMatcherSC <: AbstractMatcher
    root::Σ
    ground_subterms::Dict{AbstractTerm,UInt}
    alien_subterms::Vector{AbstractMatcher}
    linear_variables::Vector{Variable}
end

function compile(t::ACTerm, V)
    ground_subterms = Dict{AbstractTerm,UInt}()
    alien_subterms = AbstractMatcher[]
    linear_variables = Variable[]

    V′ = copy(V)

    for (s, k) ∈ t.args
        if isempty(vars(s))
            ground_subterms[s] = k
        elseif isa(s, AbstractTerm) && k == 1
            svars = setdiff(vars(s), V)
            for other ∈ keys(t.args)
                other == s && continue
                isempty(svars ∩ vars(other)) || error("AC pattern not yet supported: $t")
            end

            s_matcher, sV = compile(s, V)
            push!(alien_subterms, s_matcher)
            union!(V′, sV)
        elseif isa(s, Variable) && k == 1 && s ∉ V
            push!(linear_variables, s)
        else
            error("AC pattern not yet supported: $t")
        end
    end

    isempty(linear_variables) && error("AC pattern not yet supported: $t")
    length(alien_subterms) ≤ 1 || error("AC pattern not yet supported: $t")

    union!(V′, linear_variables)

    return ACMatcherSC(t.root, ground_subterms, alien_subterms, linear_variables), V′
end


struct ACSubproblemSC <: AbstractSubproblem
    iter
end

function _multiplicities_to_vector(dict)
    args = AbstractTerm[]

    for (s, k) ∈ dict
        append!(args, fill(s, k))
    end

    args
end
_build_ac((root, linear_variables), partition) = Dict(
    x => term(ACTheory(), root, args)
    for (x, args) ∈ zip(linear_variables, partition)
)
_build_ac(A::ACMatcherSC) = Base.Fix1(_build_ac, (A.root, A.linear_variables))
_merge(d) = Base.Fix1(merge, d)
function match!(σ, A::ACMatcherSC, t::ACTerm)
    t.root == A.root || return nothing
    args = copy(t.args)

    for (s, k) ∈ A.ground_subterms
        get(args, s, 0) ≥ k || return nothing
        args[s] -= k
        args[s] == 0 && delete!(args, s)
    end

    nargs = sum(values(args))
    naliens = length(A.alien_subterms)
    nargs ≥ length(A.linear_variables) + naliens || return nothing

    if naliens == 0
        parts = partitions(_multiplicities_to_vector(args), length(A.linear_variables))
        iter = LazyMap(_build_ac(A), LazyFlatten(LazyMap(permutations, parts)))
        return ACSubproblemSC(LazyMap(_merge(σ), iter))
    end

    @assert naliens == 1
    alien = A.alien_subterms[1]
    iters = []
    for (s, q) ∈ args
        σ′ = copy(σ)
        subproblem = match!(σ′, alien, s)
        subproblem === nothing && continue

        args′ = Dict(s′ => q′ for (s′, q′) ∈ args if s′ ≠ s)
        q == 1 || (args′[s] = q - 1)

        parts = partitions(_multiplicities_to_vector(args′), length(A.linear_variables))
        linear_iter = LazyMap(_build_ac(A), LazyFlatten(LazyMap(permutations, parts)))
        s_iters = LazyMap(m -> LazyMap(_merge(m), linear_iter), Matches(σ′, subproblem))
        push!(iters, LazyFlatten(s_iters))
    end
    return ACSubproblemSC(LazyFlatten(iters))
end


Base.iterate(iter::Matches{ACSubproblemSC}) = iterate(iter.s.iter)
Base.iterate(iter::Matches{ACSubproblemSC}, state) = iterate(iter.s.iter, state)


struct ACRewriter <: AbstractRewriter
    rules::Dict{Σ,Vector{Pair{ACMatcherSC,Any}}}
end

rewriter(::ACTheory) = ACRewriter(Dict{Σ,Vector{Pair{ACMatcherSC,Any}}}())
function Base.push!(rw::ACRewriter, (p, b)::Pair{ACTerm})
    haskey(rw.rules, p.root) || (rw.rules[p.root] = Pair{ACMatcherSC,Any}[])
    push!(rw.rules[p.root], compile(p) => b)
    rw
end

function rewrite(rw::ACRewriter, t::ACTerm)
    haskey(rw.rules, t.root) || return nothing

    for (pattern, builder) ∈ rw.rules[t.root]
        next = iterate(match(pattern, t))
        next === nothing && continue
        σ = next[1]
        return builder(σ)::AbstractTerm
    end

    return nothing
end
