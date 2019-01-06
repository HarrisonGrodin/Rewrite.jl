export head, children


@inline head(t::Tree) = isa(t, Variable) ? t : t.head
@inline function head(t::Term)
    isa(t.tree, Variable) && return t.tree

    _head = head(t.tree::Node)
    return isa(_head, Symbol) ? _head : t.pool[_head]
end

@inline children(t::Tree) = isa(t, Node) ? t.args : Tree[]
@inline children(t::Term) = Term.(children(t.tree), t.pool)


function expr_to_tree(p::Pool, x)::Tree
    isa(x, Variable) && return x

    if isa(x, Expr)
        args = similar(x.args, Tree)
        for i ∈ eachindex(x.args)
            args[i] = expr_to_tree(p, x.args[i])
        end
        return Node(x.head, args)
    end

    return Node(push!(p, x), Tree[])
end


term_to_expr(t::Term) = term_to_expr(t.pool, t.tree)
function term_to_expr(p::Pool, t::Tree)
    isa(t, Variable) && return t
    isa(t.head, UInt) && return p[t.head]

    expr = Expr(t.head)
    append!(expr.args, term_to_expr.(p, t.args))
    return expr
end
