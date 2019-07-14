using Terms
using Test


@theory Example begin
    a => FreeTheory()
    b => FreeTheory()
    c => FreeTheory()
    f => FreeTheory()
    g => FreeTheory()
    h => FreeTheory()
    p => CTheory()
    q => CTheory()
end

a(xs...) = @term(Example, a($(xs...)))
b(xs...) = @term(Example, b($(xs...)))
c(xs...) = @term(Example, c($(xs...)))
f(xs...) = @term(Example, f($(xs...)))
g(xs...) = @term(Example, g($(xs...)))
h(xs...) = @term(Example, h($(xs...)))
p(x, y) = @term(Example, p($x, $y))
q(x, y) = @term(Example, q($x, $y))
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
