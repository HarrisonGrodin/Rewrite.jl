expr_to_term(ts::TermSet, ex::Expr) = Tree(ex.head, expr_to_term.(ts, ex.args))
expr_to_term(ts::TermSet, x)        = Tree(:POOL, [expr_to_node(ts, x)])

expr_to_node(ts::TermSet, x::Variable) = Node(VARIABLE, x.id)
expr_to_node(ts::TermSet, x)           = push!(ts, x)


term_to_expr(t::Term) = term_to_expr(t.set, t.tree)
function term_to_expr(ts::TermSet, t::Tree)
    args = term_to_expr.(ts, children(t))

    _head = head(t)
    _head === :POOL && return args[1]

    Expr(_head, args...)
end
term_to_expr(ts::TermSet, x::Node) = ts[x]
