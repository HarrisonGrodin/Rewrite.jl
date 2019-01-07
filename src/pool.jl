export Pool


struct Pool{T}
    ids::Dict{T,UInt}
    lookup::Vector{T}
    Pool{T}() where {T} = new{T}(Dict{T,UInt}(), T[])
end

Base.push!(p::Pool, ex) = Term{UInt}(expr_to_tree(to_pool(p), UInt, ex))
Base.getindex(p::Pool, t::Term) = tree_to_expr(from_pool(p), t.tree)


to_pool(p::Pool) = Base.Fix1(to_pool, p)
function to_pool(p::Pool, x)
    haskey(p.ids, x) && return p.ids[x]

    push!(p.lookup, x)
    index = UInt(length(p.lookup))
    p.ids[x] = index
    return index
end

from_pool(p::Pool) = Base.Fix1(from_pool, p)
from_pool(p::Pool, index::UInt) = p.lookup[index]
