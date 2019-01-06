export head, children


@inline head(x::Leaf) = x
@inline head(t::Branch) = t.head
@inline head(t::Term) = head(t.tree)

@inline children(x::Leaf) = Tree[]
@inline children(t::Branch) = t.args
@inline children(t::Term) = Term.(children(t.tree), t.builder)
