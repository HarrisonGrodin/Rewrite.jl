using Terms
using Test


TermA = TermBuilder{Symbol}()

@testset "match" begin
    x = Variable()
    y = Variable()

    subjects = [:a, :(g(a)), :(a + b * f(c)), :([m, n]), x, y]

    expr = x
    @testset "$expr" begin
        p = TermA(expr)
        @testset for k₁ ∈ subjects
            s = TermA(k₁)
            σ = match(p, s)
            @test length(σ) == 1
            @test σ(p) == s
        end
    end

    expr = :(f())
    @testset "$expr" begin
        p = TermA(expr)
        @testset begin
            s = TermA(:(f()))
            σ = match(p, s)
            @test isempty(σ)
            @test σ(p) == s
        end
        @test match(p, TermA(:(g()))) === nothing
        @test match(p, TermA(:(f(a)))) === nothing
    end

    expr = :($x + k)
    @testset "$expr" begin
        p = TermA(expr)
        @testset for k₁ ∈ subjects
            s = TermA(:($k₁ + k))
            σ = match(p, s)
            @test length(σ) == 1
            @test σ(p) == s
        end
        @test match(p, TermA(:(a + b))) === nothing
        @test match(p, TermA(:(a - k))) === nothing
        @test match(p, TermA(:(k + $x))) === nothing
    end

    expr = :($x - f($y))
    @testset "$expr" begin
        p = TermA(expr)
        @testset for k₁ ∈ subjects, k₂ ∈ subjects
            s = TermA(:($k₁ - f($k₂)))
            σ = match(p, s)
            @test length(σ) == 2
            @test σ(p) == s
        end
        @test match(p, TermA(:(f(a) + b))) === nothing
    end

    expr = :($x + f($x))
    @testset "$expr" begin
        p = TermA(expr)
        @testset for k₁ ∈ subjects
            s = TermA(:($k₁ + f($k₁)))
            σ = match(p, s)
            @test length(σ) == 1
            @test σ(p) == s
        end
        @test match(p, TermA(:(a + f(b)))) === nothing
    end

    expr = :(TypeName{$x, $x, $y})
    @testset "$expr" begin
        p = TermA(expr)
        @testset for k₁ ∈ subjects, k₂ ∈ subjects
            s = TermA(expr)
            σ = match(p, s)
            @test length(σ) == 2
            @test σ(p) == s
        end
        @test match(p, TermA(:(OtherName{a, a, b}))) === nothing
        @test match(p, TermA(:([a, a, b]))) === nothing
    end
end
