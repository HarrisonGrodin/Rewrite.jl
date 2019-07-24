export Variable


mutable struct Variable end

Base.show(io::IO, x::Variable) = print(io, "Variable(#=", objectid(x), "=#)")


Base.convert(::Type{Expr}, x::Variable) = x

vars(x::Variable) = Set([x])
matcher(x::Variable, V) = (x, push!(copy(V), x))
@inline function match!(σ, x::Variable, t::AbstractTerm)
    if haskey(σ, x)
        σ[x] == t || return nothing
    else
        σ[x] = t
    end
    return EmptySubproblem()
end
replace(x::Variable, σ) = σ[x]

>ₜ(::Variable, ::AbstractTerm) = false
>ₜ(::AbstractTerm, ::Variable) = true
>ₜ(x::Variable, y::Variable) = objectid(x) > objectid(y)

function compile(x::Variable, V)
    fn_name = gensym(:match!_var)
    empty = EmptySubproblem()
    body = if x ∈ V
        :(σ[$x] == t ? $empty : nothing)
    else
        quote
            if haskey(σ, $x)
                σ[$x] == t ? $empty : nothing
            else
                σ[$x] = t
                $empty
            end
        end
    end

    fn_name, Expr(:block, Expr(:function, :($fn_name(σ, t)), body))
end
