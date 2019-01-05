expr_to_term(ts::TermSet, ex::Expr)    = TermTree(ex.head, expr_to_term.(ts, ex.args))
expr_to_term(ts::TermSet, x)           = TermTree(:POOL, [expr_to_node(ts, x)])

expr_to_node(ts::TermSet, x::Variable) = Node(VARIABLE, length(push!(ts.vars, x)))
expr_to_node(ts::TermSet, x)           = Node(CONSTANT, length(push!(ts.pool, x)))


term_to_expr(t::Term) = term_to_expr(t.set, t.term)
function term_to_expr(ts::TermSet, t::TermTree)
    args = term_to_expr.(ts, children(t))

    _head = head(t)
    _head === :POOL && return args[1]

    Expr(_head, args...)
end
term_to_expr(ts::TermSet, x::Node) = ts[x]
