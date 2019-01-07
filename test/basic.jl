using Terms
using Test


@testset "Variable" begin
    x = Variable()
    y = Variable()
    @test x == x
    @test x ≠ y
end

@testset "Term" begin

    x = Variable()

    @testset "construction" begin
        @test isa(Term(3), Term{Int})
        @test isa(Term(:x), Term{Symbol})
        @test isa(Term(x), Term{Variable})

        t1 = Term(3, [Term(4),   Term(5)])
        @test isa(t1, Term{Int})
        @test t1.head::Int === 3
        @test t1.args[1].head === 4

        t2 = Term(3, [Term(4.0), Term(5)])
        @test isa(t2, Term{Float64})
        @test t2.head::Float64 === 3.0
        @test t2.args[1].head::Float64 === 4.0

        t3 = Term{Int}(3, [Term(4.0), Term(5)])
        @test isa(t3, Term{Int})
        @test t3.head::Int === 3
        @test t3.args[1].head::Int === 4

        t4 = Term(:call, [Term(:+), Term(:a), Term(x)])
        @test isa(t4, Term{Union{Symbol, Variable}})
        @test t4.head::Symbol === :call
        @test t4.args[3].head === x
    end

    TermA = Term{Union{Variable, Symbol, Int}}

    @testset "conversion" begin
        @test convert(TermA, :(x + 2y)) == convert(TermA, :(x + 2y))
        @test convert(TermA, :(x + 2y)) ≠ convert(TermA, :(x + 3y))
        @test convert(TermA, :(x + 2y)) ≠ convert(TermA, :(x + 2z))
        @test convert(TermA, :(x + 2y)) ≠ convert(TermA, :($x + 2y))

        @testset "shape" begin
            function test_tree(ex::Expr, t)
                @test t.head === ex.head
                @test length(ex.args) == length(t.args)

                test_tree.(ex.args, t.args)
                nothing
            end
            function test_tree(x, t)
                @test t.head === x
                @test isempty(t.args)
                nothing
            end

            @testset for expr ∈ EXPRS
                term = convert(TermA, expr)
                @test convert(Expr, term) == expr
                test_tree(expr, term)
            end
        end
    end

end
