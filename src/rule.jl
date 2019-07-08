export Rewriter, rewrite


replace(t::Union{Variable,AbstractTerm}) = Base.Fix1(replace, t)


struct Rewriter <: AbstractRewriter
    rewriters::Dict{AbstractTheory,AbstractRewriter}
    Rewriter() = new(Dict{AbstractTheory,AbstractRewriter}())
end
Rewriter(rs...) = push!(Rewriter(), rs...)

function Base.push!(rw::Rewriter, (p, b)::Pair)
    th = theory(p)
    haskey(rw.rewriters, th) || (rw.rewriters[th] = rewriter(th))
    push!(rw.rewriters[th], p => b)
    rw
end

function rewrite(rw::Rewriter, t)
    th = theory(t)
    haskey(rw.rewriters, th) || return nothing
    rewrite(rw.rewriters[th], t)
end
