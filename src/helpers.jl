export tree
export root, children


tree(t::Term) = t.term

root(t::Tree) = t.f
root(t::Term) = root(tree(t))

children(t::Tree) = t.args
children(t::Term) = children(tree(t))
