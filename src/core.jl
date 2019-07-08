import Base: match, replace

export match


const Σ = Symbol
>ₑ(a::Σ, b::Σ) = a > b


abstract type Theory end
abstract type AbstractTerm end
abstract type AbstractMatcher end
abstract type AbstractSubproblem end
abstract type AbstractRewriter end


include("variable.jl")
include("match.jl")
include("rule.jl")
