using Terms
using Test


@testset "equality" begin
    pool1 = Pool{Union{Symbol, Int}}()
    pool2 = Pool{Union{Symbol, Int}}()
    @test pool1 == pool1
    @test pool2 == pool2
    @test pool1 ≠ pool2
end

@testset "conversion" begin
    pool = Pool{Union{Symbol, Int}}()

    @testset "$expr" for expr ∈ EXPRS
        term = push!(pool, expr)
        @test pool[term] == expr
    end
end

@testset "matching" begin
    pool = Pool{Symbol}()
    x, y = Variable(), Variable()

    pattern_ = :($x * ($x + $y))
    pattern = push!(pool, pattern_)

    subject1 = :(a * (a + var))
    σ₁ = match(pattern, push!(pool, subject1))
    @test length(σ₁) == 2
    @test pool[σ₁(pattern)] == subject1

    subject2 = :(a * (b + var))
    σ₂ = match(pattern, push!(pool, subject2))
    @test σ₂ === nothing
end
