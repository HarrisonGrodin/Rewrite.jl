using Terms
using Test


@testset "Variable" begin
    x = Variable()
    y = Variable()
    @test x ≠ y
end

@testset "Pool" begin
    TermA = Pool{Union{Symbol, Int}}()
    TermB = Pool{Union{Symbol, Int}}()
    @test TermA == TermA
    @test TermB == TermB
    @test TermA ≠ TermB
end

@testset "Term" begin
    TermA = Pool{Union{Symbol, Int}}()
    x = Variable()

    @test TermA(:(x + 2y)) == TermA(:(x + 2y))
    @test TermA(:(x + 2y)) ≠ TermA(:(x + 3y))
    @test TermA(:(x + 2y)) ≠ TermA(:(x + 2z))
    @test TermA(:(x + 2y)) ≠ TermA(:($x + 2y))

    let TermB = Pool{Union{Symbol, Int}}()
        @test TermA(:(x + 2y)) ≠ TermB(:(x + 2y))
    end

    function test_tree(b, ex::Expr, t)
        @test head(t) === ex.head

        ex_args = ex.args
        t_args = children(t)
        @test length(ex_args) == length(t_args)

        test_tree.(b, ex_args, t_args)
        nothing
    end
    function test_tree(b, x, t)
        @test head(t) === x
        @test isempty(children(t))
        nothing
    end

    exprs = [
        7,
        x,
        :(x + 2y),
        :(f(x, g(y, z), h(g))),
        :f,
        :(f()),
        :(identity(-)(5, 3)),
        :(a || (b && c)),
    ]
    @testset for expr ∈ exprs
        term = TermA(expr)
        @test convert(Expr, term) == expr
        test_tree(TermA, expr, term)
    end

end
