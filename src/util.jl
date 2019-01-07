export head, children


@inline head(t::Tree) = isa(t, Node) ? t.head : t
@inline head(t::Term) = head(t.tree)

@inline children(t::Tree) = isa(t, Node) ? t.args : Tree[]
@inline children(t::Term) = Term.(children(t.tree))


function expr_to_tree(T, x)::Tree
    isa(x, Variable) && return x

    if isa(x, Expr)
        args = similar(x.args, Tree{T})
        for i ∈ eachindex(x.args)
            args[i] = expr_to_tree(T, x.args[i])
        end
        return Node{T}(x.head, args)
    end

    return Node{T}(x, Tree{T}[])
end


term_to_expr(t::Term) = term_to_expr(t.tree)
function term_to_expr(t::Tree)
    isa(t, Node) || return t
    (isa(t.head, Symbol) && !isempty(t.args)) || return t.head

    expr = Expr(t.head)
    append!(expr.args, term_to_expr.(t.args))
    return expr
end
