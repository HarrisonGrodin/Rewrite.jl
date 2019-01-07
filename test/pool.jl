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
        @test isa(term, Term{UInt})
        @test pool[term] == expr
    end
end
