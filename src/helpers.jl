export tree
export head, children


tree(t::Term) = t.tree

head(t::Tree) = t.head === :POOL ? (@inbounds t.args[1]) : t.head
head(t::Term) = head(tree(t))

children(t::Tree) = t.head === :POOL ? (@inbounds t.args[2:end]) : t.args
children(t::Term) = children(tree(t))
