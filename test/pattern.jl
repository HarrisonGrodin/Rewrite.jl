using Terms
using Test


@testset "Variable" begin
    x = Variable()
    y = Variable()

    @test x == x
    @test y == y
    @test x ≠ y
end


@testset "match" begin
    x = Variable()
    y = Variable()

    expr = x
    @testset "$expr" begin
        p = convert(Term, expr)
        @testset for k₁ ∈ EXPRS
            s = convert(Term, k₁)
            σ = match(p, s)
            @test length(σ) == 1
            @test σ(p) == s
            @test σ[x] == convert(Term, k₁)
        end
    end

    expr = :(f())
    @testset "$expr" begin
        p = convert(Term, expr)
        @testset begin
            s = convert(Term, :(f()))
            σ = match(p, s)
            @test isempty(σ)
            @test σ(p) == s
        end
        @test match(p, convert(Term, :(g()))) === nothing
        @test match(p, convert(Term, :(f(a)))) === nothing
    end

    expr = :($x + k)
    @testset "$expr" begin
        p = convert(Term, expr)
        @testset for k₁ ∈ EXPRS
            s = convert(Term, :($k₁ + k))
            σ = match(p, s)
            @test length(σ) == 1
            @test σ(p) == s
            @test σ[x] == convert(Term, k₁)
        end
        @test match(p, convert(Term, :(a + b))) === nothing
        @test match(p, convert(Term, :(a - k))) === nothing
        @test match(p, convert(Term, :(k + $x))) === nothing
    end

    expr = :($x - f($y))
    @testset "$expr" begin
        p = convert(Term, expr)
        @testset for k₁ ∈ EXPRS, k₂ ∈ EXPRS
            s = convert(Term, :($k₁ - f($k₂)))
            σ = match(p, s)
            @test length(σ) == 2
            @test σ(p) == s
            @test σ[x] == convert(Term, k₁)
            @test σ[y] == convert(Term, k₂)
        end
        @test match(p, convert(Term, :(f(a) + b))) === nothing
    end

    expr = :($x + f($x))
    @testset "$expr" begin
        p = convert(Term, expr)
        @testset for k₁ ∈ EXPRS
            s = convert(Term, :($k₁ + f($k₁)))
            σ = match(p, s)
            @test length(σ) == 1
            @test σ(p) == s
            @test σ[x] == convert(Term, k₁)
        end
        @test match(p, convert(Term, :(a + f(b)))) === nothing
    end

    expr = :(TypeName{$x, $x, $y})
    @testset "$expr" begin
        p = convert(Term, expr)
        @testset for k₁ ∈ EXPRS, k₂ ∈ EXPRS
            s = convert(Term, :(TypeName{$k₁, $k₁, $k₂}))
            σ = match(p, s)
            @test length(σ) == 2
            @test σ(p) == s
            @test σ[x] == convert(Term, k₁)
            @test σ[y] == convert(Term, k₂)
        end
        @test match(p, convert(Term, :(OtherName{a, a, b}))) === nothing
        @test match(p, convert(Term, :([a, a, b]))) === nothing
    end
end
