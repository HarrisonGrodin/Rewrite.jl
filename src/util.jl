export head, children


@inline head(x::Variable) = x
@inline head(t::Node) = t.head
@inline function head(t::Term)
    isa(t.tree, Node) || return convert(Expr, t)
    _head = head(t.tree::Node)
    return isa(_head, Symbol) ? _head : t.builder[_head]
end

@inline children(x::Variable) = Tree[]
@inline children(t::Node) = t.args
@inline children(t::Term) = Term.(children(t.tree), t.builder)


function expr_to_tree(b::TermBuilder, ex::Expr)
    args = similar(ex.args, Tree)
    for i ∈ eachindex(ex.args)
        args[i] = expr_to_tree(b, ex.args[i])
    end
    return Node(ex.head, args)
end
expr_to_tree(b::TermBuilder, x) = Node(push!(b, x), Tree[])
expr_to_tree(::TermBuilder, x::Variable) = x


term_to_expr(t::Term) = term_to_expr(t.builder, t.tree)
function term_to_expr(b::TermBuilder, t::Node)
    isa(t.head, UInt) && return b[t.head]

    expr = Expr(t.head)
    append!(expr.args, term_to_expr.(b, t.args))
    return expr
end
term_to_expr(::TermBuilder, x::Variable) = x
