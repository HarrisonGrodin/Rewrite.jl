export tree
export head, children


@inline tree(t::Term) = t.tree

@inline head(x::Node) = x
@inline head(t::Tree) = t.head
@inline head(t::Term) = head(tree(t))

@inline children(x::Node) = Union{Node, Tree}[]
@inline children(t::Tree) = t.args
@inline children(t::Term) = children(tree(t))
