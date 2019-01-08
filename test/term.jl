using Terms
using Test


@testset "construction" begin
    @test convert(Term, :(x + 2y)) == convert(Term, :(x + 2y))
    @test convert(Term, :(x + 2y)) ≠ convert(Term, :(x + 3y))
    @test convert(Term, :(x + 2y)) ≠ convert(Term, :(x + 2z))

    function test_tree(ex::Expr, t::Term)
        @test root(t) === ex.head
        @test length(children(t)) == length(ex.args)

        test_tree.(ex.args, children(t))
        nothing
    end
    function test_tree(x, t::Term)
        @test root(t) === x
        @test isempty(children(t))
        nothing
    end

    @testset for expr ∈ EXPRS
        term = convert(Term, expr)
        @test convert(Expr, term) == expr
        test_tree(expr, term)
    end
end
