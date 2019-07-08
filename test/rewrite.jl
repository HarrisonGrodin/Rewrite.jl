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

@testset "free, custom" begin
    rw = Rewriter(
        f(x) => (σ -> g(σ[x], σ[x])),
    )

    @test rewrite(rw, f(a())) == g(a(), a())
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
        F, T = a(), b()
        and, or = p, q
        rw = Rewriter(
            and(x, F) => replace(F),
            and(x, T) => replace(x),
            and(x, x)   => replace(x),
            or(x, F) => replace(x),
            or(x, T) => replace(T),
            or(x, x)   => replace(x),
            f(and(x, y)) => replace(or(f(x), f(y))),
            f(or(x, y)) => replace(and(f(x), f(y))),
            f(f(x)) => replace(x),
        )

        A, B, C = FreeTerm.((:A, :B, :C), Ref([]))

        @test rewrite(rw, and(A, f(f(A)))) == A
        @test rewrite(rw, and(or(F, F), B)) == F
    end

    @testset "natural arithmetic" begin
        z = FreeTerm(:z, [])
        s(n) = FreeTerm(:s, [n])
        _nat(n) = n == 0 ? z : s(_nat(n - 1))

        add(m, n) = FreeTerm(:add, [m, n])
        mul(m, n) = FreeTerm(:mul, [m, n])

        rw = Rewriter(
            add(x, z)    => replace(x),
            add(x, s(y)) => replace(s(add(x, y))),
            mul(x, z)    => replace(z),
            mul(x, s(y)) => replace(add(x, mul(x, y))),
        )

        @testset "$x * $y" for x ∈ 0:5, y ∈ 0:5
            @test rewrite(rw, mul(_nat(x), _nat(y))) == _nat(x * y)
        end
    end

    @testset "list reverse" begin
        nil = FreeTerm(:nil, [])
        cons(x, xs) = FreeTerm(:cons, [x, xs])
        rev(l) = FreeTerm(:rev, [l])
        rev_aux(l, acc) = FreeTerm(:rev_aux, [l, acc])

        function _from(arr)
            l = nil
            for x ∈ reverse(arr)
                l = cons(x, l)
            end
            return l
        end

        rw = Rewriter(
            rev_aux(nil, x)        => replace(x),
            rev_aux(cons(x, y), z) => replace(rev_aux(y, cons(x, z))),
            rev(x)                 => replace(rev_aux(x, nil)),
        )

        arr = [FreeTerm(Symbol(c), []) for c ∈ 'a':'z']
        @test rewrite(rw, rev(nil)) == nil
        @test rewrite(rw, rev(_from(arr))) == _from(reverse(arr))
    end
end
