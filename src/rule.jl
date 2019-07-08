export Rule, rewrite


replace(t::Union{Variable,AbstractTerm}) = Base.Fix1(replace, t)


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
