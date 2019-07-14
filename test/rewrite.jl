@testset "empty" begin
    rw = Rewriter()
    @test rewrite(rw, a()) == a()
    @test rewrite(rw, f(a())) == f(a())
end

@testset "free, simple" begin
    rw = Rewriter(f(x) => replace(g(x)))
    @test rewrite(rw, f(a())) == g(a())
    @test rewrite(rw, h(f(a()))) == h(g(a()))
    @test rewrite(rw, g(a())) == g(a())
    @test rewrite(rw, h(a())) == h(a())
end

@testset "free, complex" begin
    @testset "orthogonal" begin
        rw = Rewriter(
            f(x)       => replace(g(x)),
            h(x, x, y) => replace(p(x, y)),
        )

        @test rewrite(rw, f(a())) == g(a())
        @test rewrite(rw, h(a(), a(), b())) == p(a(), b())
        @test rewrite(rw, h(a(), b(), b())) == h(a(), b(), b())
    end

    @testset "overlapping" begin
        rw = Rewriter(
            f(x)    => replace(g(x)),
            f(g(x)) => replace(h(x)),
        )

        @test rewrite(rw, f(a())) == g(a())
        @test rewrite(rw, f(g(a()))) ∈ [g(g(a())), h(a())]
        @test rewrite(rw, g(a())) == g(a())
    end

    @testset "identical" begin
        rw = Rewriter(
            f(x) => replace(g(x)),
            f(x) => replace(h(x)),
        )

        @test rewrite(rw, f(a())) ∈ [g(a()), h(a())]
        @test rewrite(rw, f(f(a()))) ∈ [g(g(a())), g(h(a())), h(g(a())), h(h(a()))]
    end
end

@testset "commutative, simple" begin
    lhs = p(x, x)
    rhs = x
    rw = Rewriter(lhs => replace(rhs))
    @test rewrite(rw, p(a(), a())) == a()
    @test rewrite(rw, p(b(), b())) == b()
    @test rewrite(rw, p(a(), b())) == p(a(), b())

    rw = Rewriter()
    push!(rw, lhs => replace(rhs))
    @test rewrite(rw, p(a(), a())) == a()
end

@testset "commutative, complex" begin
    @testset "orthogonal" begin
        rw = Rewriter(
            p(a(), x)   => replace(x),
            p(b(), b()) => replace(c()),
        )

        @test rewrite(rw, p(a(), b())) == b()
        @test rewrite(rw, f(p(a(), b()))) == f(b())
    end

    @testset "overlapping" begin
        rw = Rewriter(
            p(a(), x) => replace(a()),
            p(x, b()) => replace(b()),
        )

        @test rewrite(rw, p(a(), c())) == a()
        @test rewrite(rw, p(b(), c())) == b()
        @test rewrite(rw, p(a(), b())) ∈ [a(), b()]
    end

    @testset "identical" begin
        rw = Rewriter(
            p(x, y) => replace(q(x, x)),
            q(x, x) => replace(a()),
            q(x, x) => replace(b()),
        )

        @test rewrite(rw, p(c(), c())) ∈ [a(), b()]
    end
end


@testset "sample cases" begin
    @testset "boolean logic" begin
        @theory Bool begin
            F   => FreeTheory()
            T   => FreeTheory()
            and => CTheory()
            or  => CTheory()
            not => FreeTheory()
        end

        @rules Prop Bool [x, y] begin
            and(x, F) := F
            and(x, T) := x
            and(x, x) := x

            or(x, F) := x
            or(x, T) := T
            or(x, x) := x

            not(and(x, y)) := or(not(x), not(y))
            not(or(x, y))  := and(not(x), not(y))
            not(not(x)) := x
        end

        @test rewrite(Prop, @term(Bool, and(A, not(not(A))))) == @term(Bool, A)
        @test rewrite(Prop, @term(Bool, and(or(F, F), B))) == @term(Bool, F)
    end

    @testset "natural arithmetic" begin
        @theory Nat begin
            z => FreeTheory()
            s => FreeTheory()
            add => FreeTheory()
            mul => FreeTheory()
        end

        @rules Arithmetic Nat [x, y] begin
            add(x, z)    := x
            add(x, s(y)) := s(add(x, y))
            mul(x, z)    := z
            mul(x, s(y)) := add(x, mul(x, y))
        end

        _nat(n) = n == 0 ? @term(Nat, z) : @term(Nat, s($(_nat(n - 1))))

        @testset "$x * $y" for x ∈ 0:5, y ∈ 0:5
            nx, ny = _nat(x), _nat(y)
            @test rewrite(Arithmetic, @term(Nat, mul($nx, $ny))) == _nat(x * y)
        end
    end

    @testset "list reverse" begin
        @theory List begin
            nil  => FreeTheory()
            cons => FreeTheory()
            rev     => FreeTheory()
            rev_aux => FreeTheory()
        end

        @rules Reverse List [x, y, z] begin
            rev_aux(nil, x)        := x
            rev_aux(cons(x, y), z) := rev_aux(y, cons(x, z))
            rev(x)                 := rev_aux(x, nil)
        end

        function _from(arr)
            l = @term(List, nil)
            for x ∈ reverse(arr)
                l = @term(List, cons($x, $l))
            end
            return l
        end

        @testset "reverse length $n" for n ∈ 0:10
            local list
            arr = [@term(List, $(Symbol(i))) for i ∈ 1:n]
            @test rewrite(Reverse, @term(List, rev($(_from(arr))))) == _from(reverse(arr))
        end
    end
end
