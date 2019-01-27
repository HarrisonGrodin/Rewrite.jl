using Terms
using Test


x = Variable()
f = Variable()
const EXPRS = [
    7,
    -3.2,
    π,
    "hello",
    x,
    :(x + 2y),
    :(x + 2.0y),
    :(x * "!"^2),
    :($(Iterators.zip)("string", 3:8)),
    :(f(x, g(y, z), h(g))),
    :(f($x, g(y, z), h(g))),
    :(f($f(x, $x))),
    :f,
    :(f()),
    :(identity(-)(5, 3)),
    :(a || (b && c)),
]


@testset "Term"    begin include("term.jl")    end
@testset "Pattern" begin include("pattern.jl") end
