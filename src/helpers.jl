export tree
export head, children


tree(t::Term) = t.term

head(t::Tree) = t.head
head(t::Term) = head(tree(t))

children(t::Tree) = t.args
children(t::Term) = children(tree(t))
