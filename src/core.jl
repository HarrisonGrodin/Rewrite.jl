struct Tree{T}
    head::Symbol
    args::Vector{Union{T, Tree{T}}}
end


@enum Kind::UInt8 VARIABLE CONSTANT
struct Node
    kind::Kind
    index::UInt64
end

const TermTree = Tree{Node}
