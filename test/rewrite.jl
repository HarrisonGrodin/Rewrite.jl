@testset "empty" begin
    @rules Demo [] begin end
    @test Demo(a()) == a()
    @test Demo(f(a())) == f(a())
end

@testset "free, simple" begin
    @rules Demo [x] begin
        f(x) := g(x)
    end
    @test Demo(f(a())) == g(a())
    @test Demo(h(f(a()))) == h(g(a()))
    @test Demo(g(a())) == g(a())
    @test Demo(h(a())) == h(a())
end

@testset "free, complex" begin
    @testset "orthogonal" begin
        @rules Demo [x, y] begin
            f(x)       := g(x)
            h(x, x, y) := p(x, y)
        end

        @test Demo(f(a())) == g(a())
        @test Demo(h(a(), a(), b())) == p(a(), b())
        @test Demo(h(a(), b(), b())) == h(a(), b(), b())
    end

    @testset "overlapping" begin
        @rules Demo [x] begin
            f(x)    := g(x)
            f(g(x)) := h(x)
        end

        @test Demo(f(a())) == g(a())
        @test Demo(f(g(a()))) ∈ [g(g(a())), h(a())]
        @test Demo(g(a())) == g(a())
    end

    @testset "identical" begin
        @rules Demo [x] begin
            f(x) := g(x)
            f(x) := h(x)
        end

        @test Demo(f(a())) ∈ [g(a()), h(a())]
        @test Demo(f(f(a()))) ∈ [g(g(a())), g(h(a())), h(g(a())), h(h(a()))]
    end
end

@testset "commutative, simple" begin
    @rules Demo [x] begin
        p(x, x) := x
    end

    @test Demo(p(a(), a())) == a()
    @test Demo(p(b(), b())) == b()
    @test Demo(p(a(), b())) == p(a(), b())
end

@testset "commutative, complex" begin
    @testset "orthogonal" begin
        @rules Demo [x] begin
            p(a(), x)   := x
            p(b(), b()) := c()
        end

        @test Demo(p(a(), b())) == b()
        @test Demo(f(p(a(), b()))) == f(b())
    end

    @testset "overlapping" begin
        @rules Demo [x] begin
            p(a(), x) := a()
            p(x, b()) := b()
        end

        @test Demo(p(a(), c())) == a()
        @test Demo(p(b(), c())) == b()
        @test Demo(p(a(), b())) ∈ [a(), b()]
    end

    @testset "identical" begin
        @rules Demo [x, y] begin
            p(x, y) := q(x, x)
            q(x, x) := a()
            q(x, x) := b()
        end

        @test Demo(p(c(), c())) ∈ [a(), b()]
    end
end


@testset "sample cases" begin
    @testset "boolean logic" begin
        @theory! begin
            F   => FreeTheory()
            T   => FreeTheory()
            and => CTheory()
            or  => CTheory()
            not => FreeTheory()
        end

        @rules Prop [x, y] begin
            and(x, F) := F
            and(x, T) := x
            and(x, x) := x

            or(x, F) := x
            or(x, T) := T
            or(x, x) := x

            not(and(x, y)) := or(not(x), not(y))
            not(or(x, y))  := and(not(x), not(y))
            not(not(x))    := x
        end

        @test @rewrite(Prop, and(A, not(not(A)))) == @term(A)
        @test @rewrite(Prop, and(or(F, F), B)) == @term(F)
    end

    @testset "natural arithmetic" begin
        @theory! begin
            z => FreeTheory()
            s => FreeTheory()
            add => FreeTheory()
            mul => FreeTheory()
        end

        @rules Arithmetic [x, y] begin
            add(x, z)    := x
            add(x, s(y)) := s(add(x, y))
            mul(x, z)    := z
            mul(x, s(y)) := add(x, mul(x, y))
        end

        _nat(n) = n == 0 ? @term(z) : @term(s($(_nat(n - 1))))

        @testset "$x * $y" for x ∈ 0:5, y ∈ 0:5
            nx, ny = _nat(x), _nat(y)
            @test @rewrite(Arithmetic, mul($nx, $ny)) == _nat(x * y)
        end
    end

    @testset "commutative addition" begin
        @theory! begin
            z => FreeTheory()
            s => FreeTheory()
            (+) => CTheory()
        end

        @rules Addition [x, y] begin
            x + z    := x
            s(x) + y := s(x + y)
        end

        _nat(n) = n == 0 ? @term(z) : @term(s($(_nat(n - 1))))

        @test @term(a + b) == @term(b + a)
        @test @rewrite(Addition, a + s(b)) == @term(s(a + b))
        @test @rewrite(Addition, s(a) + b) == @term(s(a + b))
        @test @rewrite(Addition, s(a) + s(b)) == @term(s(s(a + b)))
        @testset "$x + $y" for x ∈ 0:5, y ∈ 0:5
            nx, ny = _nat(x), _nat(y)
            @test @rewrite(Addition, $nx + $ny) == _nat(x + y)
        end
    end

    @testset "list reverse" begin
        @theory! begin
            nil  => FreeTheory()
            cons => FreeTheory()
            rev     => FreeTheory()
            rev_aux => FreeTheory()
        end

        @rules Reverse [x, y, z] begin
            rev_aux(nil, x)        := x
            rev_aux(cons(x, y), z) := rev_aux(y, cons(x, z))
            rev(x)                 := rev_aux(x, nil)
        end

        function _from(arr)
            l = @term(nil)
            for x ∈ reverse(arr)
                l = @term(cons($x, $l))
            end
            return l
        end

        @testset "reverse length $n" for n ∈ 0:10
            local list
            arr = [@term($(Symbol(i))) for i ∈ 1:n]
            @test @rewrite(Reverse, rev($(_from(arr)))) == _from(reverse(arr))
        end
    end
end
