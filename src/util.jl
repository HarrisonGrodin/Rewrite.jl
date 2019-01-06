is_leaf(::Leaf) = true
is_leaf(::Any) = false

is_branch(::Branch) = true
is_branch(::Any) = false


function expr_to_tree(b::TermBuilder, ex::Expr)
    args = similar(ex.args, Tree)
    for i ∈ eachindex(ex.args)
        args[i] = expr_to_tree(b, ex.args[i])
    end
    Branch(ex.head, args)
end
expr_to_tree(b::TermBuilder, x::Variable) = Leaf(VARIABLE, x.id)
expr_to_tree(b::TermBuilder, x)           = push!(b, x)


term_to_expr(t::Term) = term_to_expr(t.builder, t.tree)
function term_to_expr(b::TermBuilder, t::Branch)
    expr = Expr(t.head)
    append!(expr.args, term_to_expr.(b, t.args))
    expr
end
function term_to_expr(b::TermBuilder, x::Leaf)
    x.kind === VARIABLE && return Variable(x.index)
    return b.lookup[x.index]
end
