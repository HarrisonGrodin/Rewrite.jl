function expr_to_tree(b::TermBuilder, ex::Expr)
    args = similar(ex.args, Tree)
    @simd for i ∈ eachindex(ex.args)
        @inbounds args[i] = expr_to_tree(b, ex.args[i])
    end
    Branch(ex.head, args)
end
expr_to_tree(b::TermBuilder, x::Variable) = Node(VARIABLE, x.id)
expr_to_tree(b::TermBuilder, x)           = push!(b, x)


term_to_expr(t::Term) = term_to_expr(t.builder, t.tree)
function term_to_expr(b::TermBuilder, t::Branch)
    expr = Expr(t.head)
    append!(expr.args, term_to_expr.(b, t.args))
    expr
end
term_to_expr(b::TermBuilder, x::Node) = b[x]
