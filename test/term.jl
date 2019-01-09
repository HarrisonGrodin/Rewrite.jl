using Terms
using Test


@testset "construction" begin
    x = Variable()
    k = 7.8

    t1 = @term(x)
    @test root(t1) === x
    @test isempty(children(t1))

    t2 = @term(k)
    @test root(t2) === k
    @test isempty(children(t2))

    t3 = @term("test")
    @test root(t3) == "test"
    @test isempty(children(t3))

    t4 = @term(x^2 + k)
    @test root(t4) === :call
    @test children(t4) == [@term(+), @term(x^2), @term(k)]

    t5 = @term(x^$(1+1) + k)
    @test t4 == t5
end

@testset "conversion" begin
    @test convert(Term, :(x + 2y)) == convert(Term, :(x + 2y))
    @test convert(Term, :(x + 2y)) ≠ convert(Term, :(x + 3y))
    @test convert(Term, :(x + 2y)) ≠ convert(Term, :(x + 2z))

    @test convert(Term, 2) == convert(Term, convert(Term, 2))

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

@testset "equality" begin
    @test @term(0.0) == @term(-0.0)
    @test !isequal(@term(0.0), @term(-0.0))
end

@testset "show" begin
    let x = 1
        @test sprint(show, @term([x, :x])) == "@term([1, :x])"
    end

    let x = Variable()
        @test sprint(show, @term([x, :x])) == "@term([$x, :x])"
    end

    @test sprint(show, @term(Base.Broadcast.materialize(1, 2))) ==
        "@term(Broadcast.materialize(1, 2))"
end
