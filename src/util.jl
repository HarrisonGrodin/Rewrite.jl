function expr_to_tree(ts::TermSet, ex::Expr)
    args = similar(ex.args, Union{Node, Tree})
    @simd for i ∈ eachindex(ex.args)
        @inbounds args[i] = expr_to_tree(ts, ex.args[i])
    end
    Tree(ex.head, args)
end
expr_to_tree(ts::TermSet, x::Variable) = Node(VARIABLE, x.id)
expr_to_tree(ts::TermSet, x)           = push!(ts, x)


term_to_expr(t::Term) = term_to_expr(t.set, t.tree)
function term_to_expr(ts::TermSet, t::Tree)
    expr = Expr(t.head)
    append!(expr.args, term_to_expr.(ts, t.args))
    expr
end
term_to_expr(ts::TermSet, x::Node) = ts[x]
