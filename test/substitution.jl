using Terms
using Test


TermA = Pattern{Union{Symbol, Int}}

@testset "match" begin
    x = Variable()
    y = Variable()

    expr = x
    @testset "$expr" begin
        p = convert(TermA, expr)
        @testset for k₁ ∈ EXPRS
            s = convert(TermA, k₁)
            σ = match(p, s)
            @test length(σ) == 1
            @test σ(p) == s
            @test σ[x] == convert(TermA, k₁)
        end
    end

    expr = :(f())
    @testset "$expr" begin
        p = convert(TermA, expr)
        @testset begin
            s = convert(TermA, :(f()))
            σ = match(p, s)
            @test isempty(σ)
            @test σ(p) == s
        end
        @test match(p, convert(TermA, :(g()))) === nothing
        @test match(p, convert(TermA, :(f(a)))) === nothing
    end

    expr = :($x + k)
    @testset "$expr" begin
        p = convert(TermA, expr)
        @testset for k₁ ∈ EXPRS
            s = convert(TermA, :($k₁ + k))
            σ = match(p, s)
            @test length(σ) == 1
            @test σ(p) == s
            @test σ[x] == convert(TermA, k₁)
        end
        @test match(p, convert(TermA, :(a + b))) === nothing
        @test match(p, convert(TermA, :(a - k))) === nothing
        @test match(p, convert(TermA, :(k + $x))) === nothing
    end

    expr = :($x - f($y))
    @testset "$expr" begin
        p = convert(TermA, expr)
        @testset for k₁ ∈ EXPRS, k₂ ∈ EXPRS
            s = convert(TermA, :($k₁ - f($k₂)))
            σ = match(p, s)
            @test length(σ) == 2
            @test σ(p) == s
            @test σ[x] == convert(TermA, k₁)
            @test σ[y] == convert(TermA, k₂)
        end
        @test match(p, convert(TermA, :(f(a) + b))) === nothing
    end

    expr = :($x + f($x))
    @testset "$expr" begin
        p = convert(TermA, expr)
        @testset for k₁ ∈ EXPRS
            s = convert(TermA, :($k₁ + f($k₁)))
            σ = match(p, s)
            @test length(σ) == 1
            @test σ(p) == s
            @test σ[x] == convert(TermA, k₁)
        end
        @test match(p, convert(TermA, :(a + f(b)))) === nothing
    end

    expr = :(TypeName{$x, $x, $y})
    @testset "$expr" begin
        p = convert(TermA, expr)
        @testset for k₁ ∈ EXPRS, k₂ ∈ EXPRS
            s = convert(TermA, :(TypeName{$k₁, $k₁, $k₂}))
            σ = match(p, s)
            @test length(σ) == 2
            @test σ(p) == s
            @test σ[x] == convert(TermA, k₁)
            @test σ[y] == convert(TermA, k₂)
        end
        @test match(p, convert(TermA, :(OtherName{a, a, b}))) === nothing
        @test match(p, convert(TermA, :([a, a, b]))) === nothing
    end
end
