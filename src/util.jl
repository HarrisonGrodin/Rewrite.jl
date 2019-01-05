function expr_to_term(ts::TermSet, ex::Expr)
    ex.head === :call || throw(ArgumentError("invalid expression head: :$(ex.head)"))

    fn, args = ex.args[1], ex.args[2:end]
    TermTree(expr_to_node(ts, fn), expr_to_term.(ts, args))
end
expr_to_term(ts::TermSet, x) = TermTree(expr_to_node(ts, x), [])

expr_to_node(ts::TermSet, x::Variable) = Node(VARIABLE, length(push!(ts.vars, x)))
expr_to_node(ts::TermSet, x)           = Node(CONSTANT, length(push!(ts.pool, x)))


term_to_expr(t::Term) = term_to_expr(t.set, t.term)
function term_to_expr(ts::TermSet, t::TermTree)
    node, children = term_to_expr(ts, t.f), term_to_expr.(ts, t.args)

    isempty(children) && return node
    Expr(:call, node, children...)
end
function term_to_expr(ts::TermSet, x::Node)
    x.kind === VARIABLE && return ts.vars[x.index]
    x.kind === CONSTANT && return ts.pool[x.index]
    throw(ArgumentError("invalid kind: $(x.kind)"))
end
