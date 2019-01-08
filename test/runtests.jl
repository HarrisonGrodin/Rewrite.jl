using Terms
using Test


x = Variable()
f = Variable()
const EXPRS = [
    7,
    x,
    :(x + 2y),
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
