export head, children


@inline head(t::Tree) = isa(t, Node) ? t.head : t
@inline head(t::Term) = head(t.tree)

@inline children(t::Tree) = isa(t, Node) ? t.args : []
@inline children(t::Term{T}) where {T} = Term{T}.(children(t.tree))


function expr_to_tree(f::Function, T, x)::Tree
    isa(x, Variable) && return x

    if isa(x, Expr)
        args = similar(x.args, Tree{T})
        for i ∈ eachindex(x.args)
            args[i] = expr_to_tree(f, T, x.args[i])
        end
        return Node{T}(f(x.head), args)
    end

    return Node{T}(f(x), Tree{T}[])
end
expr_to_tree(T, x) = expr_to_tree(identity, T, x)


function tree_to_expr(f::Function, t::Tree)
    isa(t, Node) || return t
    _head = f(t.head)
    (isa(_head, Symbol) && !isempty(t.args)) || return _head

    expr = Expr(_head)
    append!(expr.args, tree_to_expr.(f, t.args))
    return expr
end
tree_to_expr(t::Tree) = tree_to_expr(identity, t)
