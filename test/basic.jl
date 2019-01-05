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

        function test_tree(ts, ex::Expr, t)
            @assert ex.head === :call

            ex_args = ex.args[2:end]
            t_children = children(t)

            @test ts[root(t)] == ex.args[1]
            @test length(ex_args) == length(t_children)

            test_tree.(ts, ex_args, t_children)
            nothing
        end
        function test_tree(ts, x, t)
            @test ts[root(t)] == x
            @test isempty(children(t))
            nothing
        end

        exprs = [7, x, :(x + 2y), :(f(x, g(y, z), h(g))), :f, :(f()), :(identity(-)(5, 3))]
        @testset for expr ∈ exprs
            term = TermA(expr)
            @test Expr(term) == expr
            test_tree(TermA, expr, term)
        end

    end

end
