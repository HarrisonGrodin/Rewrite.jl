@testset "empty" begin
    rw = Rewriter()
    @test rewrite(rw, a()) == a()
    @test rewrite(rw, f(a())) == f(a())
end

@testset "free, simple" begin
    rw = Rewriter(f(x) => replace(g(x)))
    @test rewrite(rw, f(a())) == g(a())
    @test rewrite(rw, h(f(a()))) == h(g(a()))
    @test rewrite(rw, g(a())) == g(a())
    @test rewrite(rw, h(a())) == h(a())
end

@testset "free, complex" begin
    @testset "orthogonal" begin
        rw = Rewriter(
            f(x)       => replace(g(x)),
            h(x, x, y) => replace(p(x, y)),
        )

        @test rewrite(rw, f(a())) == g(a())
        @test rewrite(rw, h(a(), a(), b())) == p(a(), b())
        @test rewrite(rw, h(a(), b(), b())) == h(a(), b(), b())
    end

    @testset "overlapping" begin
        rw = Rewriter(
            f(x)    => replace(g(x)),
            f(g(x)) => replace(h(x)),
        )

        @test rewrite(rw, f(a())) == g(a())
        @test rewrite(rw, f(g(a()))) ∈ [g(g(a())), h(a())]
        @test rewrite(rw, g(a())) == g(a())
    end

    @testset "identical" begin
        rw = Rewriter(
            f(x) => replace(g(x)),
            f(x) => replace(h(x)),
        )

        @test rewrite(rw, f(a())) ∈ [g(a()), h(a())]
        @test rewrite(rw, f(f(a()))) ∈ [g(g(a())), g(h(a())), h(g(a())), h(h(a()))]
    end
end

@testset "free, custom" begin
    rw = Rewriter(
        f(x) => (σ -> g(σ[x], σ[x])),
    )

    @test rewrite(rw, f(a())) == g(a(), a())
end

@testset "commutative, simple" begin
    lhs = p(x, x)
    rhs = x
    rw = Rewriter(lhs => replace(rhs))
    @test rewrite(rw, p(a(), a())) == a()
    @test rewrite(rw, p(b(), b())) == b()
    @test rewrite(rw, p(a(), b())) == p(a(), b())

    rw = Rewriter()
    push!(rw, lhs => replace(rhs))
    @test rewrite(rw, p(a(), a())) == a()
end

@testset "commutative, complex" begin
    @testset "orthogonal" begin
        rw = Rewriter(
            p(a(), x)   => replace(x),
            p(b(), b()) => replace(c()),
        )

        @test rewrite(rw, p(a(), b())) == b()
        @test rewrite(rw, f(p(a(), b()))) == f(b())
    end

    @testset "overlapping" begin
        rw = Rewriter(
            p(a(), x) => replace(a()),
            p(x, b()) => replace(b()),
        )

        @test rewrite(rw, p(a(), c())) == a()
        @test rewrite(rw, p(b(), c())) == b()
        @test rewrite(rw, p(a(), b())) ∈ [a(), b()]
    end

    @testset "identical" begin
        rw = Rewriter(
            p(x, y) => replace(q(x, x)),
            q(x, x) => replace(a()),
            q(x, x) => replace(b()),
        )

        @test rewrite(rw, p(c(), c())) ∈ [a(), b()]
    end
end


@testset "sample cases" begin
    @testset "boolean logic" begin
        F, T = a(), b()
        and, or = p, q
        rw = Rewriter(
            and(x, F) => replace(F),
            and(x, T) => replace(x),
            and(x, x)   => replace(x),
            or(x, F) => replace(x),
            or(x, T) => replace(T),
            or(x, x)   => replace(x),
            f(and(x, y)) => replace(or(f(x), f(y))),
            f(or(x, y)) => replace(and(f(x), f(y))),
            f(f(x)) => replace(x),
        )

        A, B, C = FreeTerm.((:A, :B, :C), Ref([]))

        @test rewrite(rw, and(A, f(f(A)))) == A
        @test rewrite(rw, and(or(F, F), B)) == F
    end
end
