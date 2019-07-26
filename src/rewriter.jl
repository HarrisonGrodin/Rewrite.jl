struct Rewriter <: AbstractRewriter
    rewriters::Dict{AbstractTheory,AbstractRewriter}
    Rewriter() = new(Dict{AbstractTheory,AbstractRewriter}())
end

function Base.push!(rw::Rewriter, (p, b)::Pair{<:AbstractTerm})
    th = theory(p)
    haskey(rw.rewriters, th) || (rw.rewriters[th] = rewriter(th))
    push!(rw.rewriters[th], p => b)
    rw
end

function compile(rw::Rewriter)
    fn_name = gensym(:rewrite)

    rewriter_exprs = Expr[]

    rewriters = Dict()
    for (th, rewriter) ∈ rw.rewriters
        fn, expr = compile(rewriter)
        rewriters[th] = fn
        push!(rewriter_exprs, expr)
    end

    tree = gensym(:rewriter_TREE)

    fn_name, quote
        $(rewriter_exprs...)
        $tree = Dict($((:($th => $fn) for (th, fn) ∈ rewriters)...))
        function $fn_name(t)
            while true
                th = $theory(t)
                t = map($fn_name, t)
                $haskey($tree, th) || return t

                t′ = $tree[th](t)
                t′ === nothing && return t
                t = t′
            end
        end
    end
end
