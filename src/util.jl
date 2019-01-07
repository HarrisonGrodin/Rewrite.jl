function expr_to_term(f::Function, T, x)
    isa(x, Expr) || return Term{T}(f(x), Term{T}[])

    args = similar(x.args, Term{T})
    for i ∈ eachindex(x.args)
        args[i] = expr_to_term(f, T, x.args[i])
    end
    return Term{T}(f(x.head), args)
end
expr_to_term(T, x) = expr_to_term(identity, T, x)


function term_to_expr(f::Function, t::Term)
    head = f(t.head)
    isempty(t.args) && return head
    isa(head, Symbol) || throw(ArgumentError("invalid `Expr` head ($head)"))

    expr = Expr(head)
    append!(expr.args, term_to_expr.(f, t.args))
    return expr
end
term_to_expr(t::Term) = term_to_expr(identity, t)
