using Terms
using Test


@testset "construction" begin

    @testset "Variable" begin
        x = Variable(:x)
        y = Variable(:y)
        @test x ≠ y

        x′ = Variable(:x)
        @test x ≠ x′
    end

    @testset "TermSet" begin
        TermA = TermSet{Symbol, Union{Symbol, Int}}()
        TermB = TermSet{Symbol, Union{Symbol, Int}}()
        @test TermA == TermA
        @test TermB == TermB
        @test TermA ≠ TermB
    end

    @testset "Term" begin
        TermA = TermSet{Symbol, Union{Symbol, Int}}()
        x = Variable(:x)

        @test TermA(:(x + 2y)) == TermA(:(x + 2y))
        @test TermA(:(x + 2y)) ≠ TermA(:(x + 3y))
        @test TermA(:(x + 2y)) ≠ TermA(:(x + 2z))
        @test TermA(:(x + 2y)) ≠ TermA(:($x + 2y))

        let TermB = TermSet{Symbol, Union{Symbol, Int}}()
            @test TermA(:(x + 2y)) ≠ TermB(:(x + 2y))
        end

        exprs = [7, x, :(x + 2y), :(f(x, g(y, z), h(g)))]
        @testset "inverse: $expr" for expr ∈ exprs
            @test Expr(TermA(expr)) == expr
        end
    end

end
