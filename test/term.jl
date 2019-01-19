using Terms
using Test


@testset "construction" begin
    x = Variable()
    k = 7.8

    t1 = @term(x)
    @test root(t1) === x
    @test isleaf(t1)
    @test isempty(eachindex(t1))
    @test isempty(children(t1))
    @test_throws BoundsError(t1, 1) t1[1]

    t2 = @term(k)
    @test root(t2) === k
    @test isleaf(t2)
    @test isempty(eachindex(t2))
    @test isempty(children(t2))

    t3 = @term("test")
    @test root(t3) == "test"
    @test isleaf(t3)
    @test isempty(eachindex(t3))
    @test isempty(children(t3))

    t4 = @term(x^2 + k)
    @test root(t4) === :call
    @test !isleaf(t4)
    @test eachindex(t4) == 1:3
    @test children(t4) == [@term(+), @term(x^2), @term(k)]
    @test t4[1] == @term(+)
    @test t4[2] == @term(x^2)
    @test t4[2,3] == t4[2][3] == @term(2)
    @test_throws BoundsError(t4[2,3], 4) t4[2,3,4]
    @test t4[3] == @term(k)
    @test_throws BoundsError(t4, 5) t4[5]

    t5 = @term(x^$(1+1) + k)
    @test t4 == t5
end

struct WrapperTest
    t::Term
end
Base.convert(::Type{Term}, w::WrapperTest) = w.t

@testset "combination" begin
    a = @term(1 + 2)
    b = @term(3)
    t = @term(a ^ b)

    @test root(t) === :call
    @test children(t) == [@term(^), a, b]
    @test t == @term((1 + 2) ^ 3)

    @test @term(1 + $(@term(sin(2)))) == @term(1 + sin(2))

    w = WrapperTest(@term(sin(2a)))
    t2 = @term(w + 1)
    @test root(t2) === :call
    @test children(t2) == [@term(+), @term(sin(2*(1+2))), @term(1)]
    @test t2 == @term(sin(2*(1+2)) + 1)
end

@testset "conversion" begin
    @test convert(Term, :(x + 2y)) == convert(Term, :(x + 2y))
    @test convert(Term, :(x + 2y)) ≠ convert(Term, :(x + 3y))
    @test convert(Term, :(x + 2y)) ≠ convert(Term, :(x + 2z))

    @test convert(Term, 2) == convert(Term, convert(Term, 2))

    function test_tree(ex::Expr, t::Term)
        @test root(t) === ex.head
        @test eachindex(t) == 1:length(ex.args)
        @test length(children(t)) == length(ex.args)
        @test eltype(children(t)) <: Term

        test_tree.(ex.args, children(t))
        nothing
    end
    function test_tree(x, t::Term)
        @test root(t) === x
        @test isempty(eachindex(t))
        @test isempty(children(t))
        @test eltype(children(t)) <: Term
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
    @test sprint(show, @term(2)) == "@term(2)"
    @test sprint(show, @term(-3.7)) == "@term(-3.7)"
    @test sprint(show, @term("test")) == "@term(\"test\")"
    @test sprint(show, @term(:x)) == "@term(:x)"
    @test sprint(show, @term(:ω)) == "@term(:ω)"

    let x = 1
        @test sprint(show, @term([x, :x])) == "@term([1, :x])"
    end

    let x = Variable()
        @test sprint(show, @term([x, :x])) == "@term([$x, :x])"
    end

    @test sprint(show, @term(sin(π) + (3 - 5))) == "@term(sin($π) + (3 - 5))"

    @test sprint(show, @term(Base.Broadcast.materialize(1, 2))) ==
        "@term(Broadcast.materialize(1, 2))"
end
