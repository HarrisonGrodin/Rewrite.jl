export Pool


struct Pool{T}
    ids::Dict{T,UInt}
    lookup::Vector{T}
    Pool{T}() where {T} = new{T}(Dict{T,UInt}(), T[])
end

Base.push!(p::Pool, ex) = expr_to_term(to_pool(p), Union{UInt,Variable}, ex)
Base.getindex(p::Pool, t::Term) = term_to_expr(from_pool(p), t)


to_pool(p::Pool) = Base.Fix1(to_pool, p)
function to_pool(p::Pool, x)
    isa(x, Variable) && return x
    haskey(p.ids, x) && return p.ids[x]

    push!(p.lookup, x)
    index = UInt(length(p.lookup))
    p.ids[x] = index
    return index
end

from_pool(p::Pool) = Base.Fix1(from_pool, p)
from_pool(p::Pool, x) = isa(x, UInt) ? p.lookup[x] : x
