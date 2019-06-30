compatible(::Nothing, ::Nothing) = false
compatible(::Dict, ::Nothing) = false
compatible(::Nothing, ::Dict) = false
function compatible(p::Dict, q::Dict)
    length(p) < length(q) && ((p, q) = (q, p))
    for (x, t) ∈ q
        haskey(p, x) && (p[x] == t || return false)
    end
    return true
end

p ⊔ q = compatible(p, q) ? merge(p, q) : nothing


@inline _aiterate(p) = (p, ())
@inline function _aiterate(p, iter1, rest...)
    restres = _aiterate(p, rest...)
    restres === nothing && return nothing
    (P, states) = restres

    thisres = iterate(Matches(P, iter1))
    thisres === nothing && return nothing
    (P′, state) = thisres

    return (P′, ((P, state), states...))
end

@inline _aiterate1(p, ::Tuple{}, ::Tuple{}) = nothing
@inline function _aiterate1(p, iters, states)
    iter1 = first(iters)
    (P, state1) = first(states)
    next = iterate(Matches(P, iter1), state1)
    reststates = Base.tail(states)

    if next === nothing
        restnext = _aiterate1(p, Base.tail(iters), reststates)
        restnext === nothing && return nothing
        (P, reststates) = restnext

        next = iterate(Matches(P, iter1))
        next === nothing && return nothing
    end

    (P′, state) = next
    return (P′, ((P, state), reststates...))
end
