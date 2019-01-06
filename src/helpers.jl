export head, children


@inline head(x::Leaf) = x
@inline head(t::Branch) = t.head
@inline head(t::Term) = is_branch(t.tree) ? head(t.tree::Branch) : convert(Expr, t)

@inline children(x::Leaf) = Tree[]
@inline children(t::Branch) = t.args
@inline children(t::Term) = Term.(children(t.tree), t.builder)
