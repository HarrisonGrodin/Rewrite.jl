function expr_to_term(ts::TermSet, ex::Expr)
    args = similar(ex.args, Union{Node, Tree})
    @simd for i ∈ eachindex(ex.args)
        @inbounds args[i] = expr_to_term(ts, ex.args[i])
    end
    Tree(ex.head, args)
end
expr_to_term(ts::TermSet, x) = Tree(:POOL, Union{Node, Tree}[expr_to_node(ts, x)])

expr_to_node(ts::TermSet, x::Variable) = Node(VARIABLE, x.id)
expr_to_node(ts::TermSet, x)           = push!(ts, x)


term_to_expr(t::Term) = term_to_expr(t.set, t.tree)
function term_to_expr(ts::TermSet, t::Tree)
    args = term_to_expr.(ts, t.args)

    _head = t.head
    _head === :POOL && return @inbounds args[1]

    Expr(_head, args...)
end
term_to_expr(ts::TermSet, x::Node) = ts[x]
