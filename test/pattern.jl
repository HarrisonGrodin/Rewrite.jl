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
        @test match(p, convert(Term, 2)) === nothing
        @test match(p, convert(Term, :f)) === nothing
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
        @test match(p, convert(Term, :+)) === nothing
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

@testset "Substitution" begin
    x, y = Variable(), Variable()
    σ = match(@term(x + abs(y^3)), @term(2 + abs((-4)^3)))
    @test σ(@term(x + abs(y)^3)) == @term(2 + abs(-4)^3)
    @test σ[x] == @term(2)
    @test σ[y] == @term(-4)

    d = Dict(σ)
    @test typeof(d) <: Dict{Variable,Term}
    @test d[x] == @term(2)
    @test d[y] == @term(-4)
end
