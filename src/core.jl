import Base: match, replace

export match


const Σ = Symbol
>ₑ(a::Σ, b::Σ) = a > b


abstract type AbstractTheory end
abstract type AbstractTerm end
abstract type AbstractMatcher end
abstract type AbstractSubproblem end
abstract type AbstractRewriter end


include("variable.jl")
include("match.jl")
include("rewrite.jl")
