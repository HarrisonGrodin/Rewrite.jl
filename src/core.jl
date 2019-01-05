struct Tree{T}
    f::T
    args::Vector{Tree{T}}
end


@enum Kind::UInt8 VARIABLE CONSTANT
struct Node
    kind::Kind
    index::UInt64
end

const TermTree = Tree{Node}
