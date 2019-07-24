@testset "variable" begin
    @test x == x
    @test x ≠ y
end

@testset "free" begin
    @test a == a
    @test @term(a) == @term(a)
    @test a ≠ b
    @test f(a, a) == f(a, a)
    @test f(a, b) == f(a, b)
    @test f(a, b) ≠ f(b, a)
    @test f(x, b) == f(x, b)
    @test f(x, b) ≠ f(b, x)
end

@testset "c" begin
    @test p(a, b) == p(a, b)
    @test p(a, b) == p(b, a)
    @test p(a, b) ≠ p(a, c)
    @test p(p(a, b), c) ≠ p(a, p(b, c))
    @test p(a, p(b, c)) == p(p(c, b), a)
    @test p(p(a, b), q(a, b)) == p(q(a, b), p(a, b))
    @test p(p(x, a), q(x, b)) ≠ p(p(b, x), q(x, a))
    @test p(q(x, a), q(x, b)) == p(q(b, x), q(x, a))
    @test p(f(a, b), f(a, c)) == p(f(a, c), f(a, b))
end

@testset "ac" begin
    @test s(a, b) == s(a, b)
    @test s(a, b) == s(b, a)
    @test s(a, b, c) == s(c, a, b)
    @test s(a, x, b) == s(b, a, x)
    @test s(a, s(b, c)) == s(a, b, c)
    @test s(a, t(b, c)) ≠ s(a, b, c)
    @test s(a, s(b, c, a), s(c)) == s(a, a, b, c, c)
end
