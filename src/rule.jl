export Rule, rewrite
export Builder


struct Builder{T}
    pattern::T
end
(b::Builder)(σ) = replace(b.pattern, σ)


struct Rule{L,R}
    pattern::L
    replace::R
end

function rewrite(r::Rule, t)
    next = iterate(match(r.pattern, t))
    next === nothing && return nothing
    σ = next[1]
    return r.replace(σ)
end
