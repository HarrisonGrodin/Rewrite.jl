using Terms
using Test

a(xs...) = FreeTerm(:a, collect(xs))
b(xs...) = FreeTerm(:b, collect(xs))
c(xs...) = FreeTerm(:c, collect(xs))
f(xs...) = FreeTerm(:f, collect(xs))
g(xs...) = FreeTerm(:g, collect(xs))
h(xs...) = FreeTerm(:h, collect(xs))
p(x, y) = CTerm(:p, x, y)
q(x, y) = CTerm(:q, x, y)
x, y, z = Variable(), Variable(), Variable()


@testset "construction" begin
    include("construction.jl")
end

@testset "match" begin
    include("match.jl")
end

@testset "rewrite" begin
    include("rewrite.jl")
end
