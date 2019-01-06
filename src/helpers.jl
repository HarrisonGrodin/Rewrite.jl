export head, children


@inline head(x::Node) = x
@inline head(t::Branch) = t.head
@inline head(t::Term) = head(t.tree)

@inline children(x::Node) = Tree[]
@inline children(t::Branch) = t.args
@inline children(t::Term) = Term.(children(t.tree), t.builder)
