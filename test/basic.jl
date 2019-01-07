using Terms
using Test


@testset "Variable" begin
    x = Variable()
    y = Variable()
    @test x == x
    @test x ≠ y
end

@testset "Node" begin
    TermA = Term{Union{Variable, Symbol, Int}}
    x = Variable()

    @testset "equality" begin
        @test convert(TermA, :(x + 2y)) == convert(TermA, :(x + 2y))
        @test convert(TermA, :(x + 2y)) ≠ convert(TermA, :(x + 3y))
        @test convert(TermA, :(x + 2y)) ≠ convert(TermA, :(x + 2z))
        @test convert(TermA, :(x + 2y)) ≠ convert(TermA, :($x + 2y))
    end

    @testset "shape" begin
        function test_tree(ex::Expr, t)
            @test head(t) === ex.head

            ex_args = ex.args
            t_args = children(t)
            @test length(ex_args) == length(t_args)

            test_tree.(ex_args, t_args)
            nothing
        end
        function test_tree(x, t)
            @test head(t) === x
            @test isempty(children(t))
            nothing
        end

        @testset for expr ∈ EXPRS
            term = convert(TermA, expr)
            @test convert(Expr, term) == expr
            test_tree(expr, term)
        end
    end

end
