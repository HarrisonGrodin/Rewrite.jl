@testset "variable" begin
    @test x == x
    @test x ≠ y
end

@testset "free" begin
    @test a() == a()
    @test a() ≠ b()
    @test f(a(), a()) == f(a(), a())
    @test f(a(), b()) == f(a(), b())
    @test f(a(), b()) ≠ f(b(), a())
    @test f(x, b()) == f(x, b())
    @test f(x, b()) ≠ f(b(), x)
end

@testset "c" begin
    @test p(a(), b()) == p(a(), b())
    @test p(a(), b()) == p(b(), a())
    @test p(a(), b()) ≠ p(a(), c())
    @test p(a(), p(b(), c())) == p(p(c(), b()), a())
    @test p(q(x, a()), q(x, b())) == p(q(b(), x), q(x, a()))
end
