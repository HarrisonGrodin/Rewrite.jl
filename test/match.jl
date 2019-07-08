TESTS = [
    "free" => [
        (
            a(),
            [
                (a(), [Dict()]),
                (a(b()), []),
                (b(), []),
                (f(a()), []),
            ]
        ),
        (
            f(a()),
            [
                (f(a()), [Dict()]),
                (f(), []),
                (f(a(), b()), []),
                (f(f(a())), []),
                (g(a()), []),
                (f(b()), []),
                (g(b()), []),
            ]
        ),
        (
            f(x),
            [
                (f(a()), [Dict(x => a())]),
                (f(b()), [Dict(x => b())]),
                (f(f(a())), [Dict(x => f(a()))]),
                (f(), []),
                (g(a()), []),
                (g(f(a())), []),
            ]
        ),
        (
            g(x, y),
            [
                (g(a(), a()), [Dict(x => a(), y => a())]),
                (g(a(), b()), [Dict(x => a(), y => b())]),
                (g(a(), b(), c()), []),
                (g(), []),
            ]
        ),
        (
            g(x, x),
            [
                (g(a(), a()), [Dict(x => a())]),
                (g(a(), b()), []),
                (g(a(), b(), c()), []),
                (g(), []),
            ]
        ),
        (
            g(x, h(x, y, c())),
            [
                (g(a(), h(a(), a(), c())), [Dict(x => a(), y => a())]),
                (g(a(), h(a(), b(), c())), [Dict(x => a(), y => b())]),
                (g(a(), h(a(), c(), c())), [Dict(x => a(), y => c())]),
                (g(a(), h(b(), b(), c())), []),
                (g(a(), f(a(), b(), c())), []),
                (f(a(), h(a(), b(), b())), []),
                (g(a(), h(a(), b(), b())), []),
            ]
        ),
    ],
    "c" => [
        (
            p(a(), a()),
            [
                (p(a(), a()), [Dict()]),
                (p(a(), b()), []),
                (q(a(), a()), []),
            ]
        ),
        (
            p(a(), b()),
            [
                (p(a(), b()), [Dict()]),
                (p(a(), a()), []),
                (q(a(), b()), []),
            ]
        ),
        (
            p(x, a()),
            [
                (p(a(), a()), [Dict(x => a())]),
                (p(a(), b()), [Dict(x => b())]),
                (q(a(), a()), []),
            ]
        ),
        (
            p(x, x),
            [
                (p(a(), a()), [Dict(x => a())]),
                (p(a(), b()), []),
                (q(a(), a()), []),
            ]
        ),
        (
            p(x, y),
            [
                (p(a(), b()), [Dict(x => a(), y => b()), Dict(x => b(), y => a())]),
                (p(a(), a()), [Dict(x => a(), y => a())]),
                (q(a(), a()), []),
            ]
        ),
        (
            p(x, p(a(), x)),
            [
                (p(a(), p(a(), a())), [Dict(x => a())]),
                (p(a(), p(a(), b())), []),
                (f(a(), p(a(), a())), []),
                (p(b(), p(a(), b())), [Dict(x => b())]),
                (p(p(a(), b()), b()), [Dict(x => b())]),
                (p(q(a(), b()), b()), []),
                (p(p(b(), b()), a()), []),
            ]
        ),
        (
            p(x, p(y, x)),
            [
                (p(a(), p(a(), a())), [Dict(x => a(), y => a())]),
                (p(a(), p(a(), b())), [Dict(x => a(), y => b())]),
                (p(b(), p(a(), c())), []),
            ]
        ),
        (
            p(x, q(y, x)),
            [
                (p(a(), q(a(), a())), [Dict(x => a(), y => a())]),
                (p(q(a(), b()), a()), [Dict(x => a(), y => b())]),
                (p(b(), q(a(), c())), []),
            ]
        ),
        (
            p(x, q(y, z)),
            [
                (p(a(), q(a(), a())), [Dict(x => a(), y => a(), z => a())]),
                (p(q(a(), b()), a()), [Dict(x => a(), y => a(), z => b()),
                                       Dict(x => a(), y => b(), z => a())]),
                (p(q(a(), b()), q(a(), c())), [Dict(x => q(a(), b()), y => a(), z => c()),
                                               Dict(x => q(a(), b()), y => c(), z => a()),
                                               Dict(x => q(a(), c()), y => a(), z => b()),
                                               Dict(x => q(a(), c()), y => b(), z => a())]),
            ]
        ),
        (
            p(q(x, y), q(y, z)),
            [
                (p(q(a(), a()), q(a(), a())), [Dict(x => a(), y => a(), z => a())]),
                (p(q(a(), b()), q(c(), b())), [Dict(x => a(), y => b(), z => c()),
                                               Dict(x => c(), y => b(), z => a())]),
            ]
        ),
        (
            p(f(x), q(x, y)),
            [
                (p(f(a()), q(a(), a())), [Dict(x => a(), y => a())]),
                (p(q(a(), b()), f(a())), [Dict(x => a(), y => b())]),
                (p(b(), q(a(), c())), []),
            ]
        ),
    ],
    "general" => [
        (
            f(p(a(), x), b()),
            [
                (f(p(a(), a()), b()), [Dict(x => a())]),
                (f(p(a(), b()), b()), [Dict(x => b())]),
                (f(p(a(), b()), c()), []),
                (f(p(b(), b()), b()), []),
            ]
        ),
        (
            f(p(a(), x), g(y)),
            [
                (f(p(a(), a()), g(b())), [Dict(x => a(), y => b())]),
                (f(p(a(), b()), g(b())), [Dict(x => b(), y => b())]),
                (f(p(a(), b()), h(c())), []),
                (f(p(b(), b()), g(b())), []),
            ]
        ),
        (
            f(q(p(a(), x), g(y)), z),
            [
                (f(q(p(a(), a()), g(b())), c()), [Dict(x => a(), y => b(), z => c())]),
                (f(q(p(a(), b()), g(b())), c()), [Dict(x => b(), y => b(), z => c())]),
                (f(q(p(a(), b()), h(c())), c()), []),
                (f(q(p(b(), b()), g(b())), c()), []),
            ]
        ),
        (
            p(x, f(p(y, z), c())),
            [
                (p(a(), f(p(b(), c()), c())), [Dict(x => a(), y => b(), z => c()),
                                               Dict(x => a(), y => c(), z => b())]),
                (p(a(), f(q(b(), c()), c())), []),
            ]
        ),
        (
            f(x, p(x, y), q(y, z)),
            [
                (f(a(), p(a(), b()), q(b(), c())), [Dict(x => a(), y => b(), z => c())]),
                (f(a(), p(b(), a()), q(b(), c())), [Dict(x => a(), y => b(), z => c())]),
                (f(a(), p(b(), a()), q(c(), b())), [Dict(x => a(), y => b(), z => c())]),
                (f(a(), p(a(), a()), q(c(), b())), []),
            ]
        ),
        (
            f(x, q(p(x, y), p(y, z))),
            [
                (f(a(), q(p(a(), a()), p(a(), b()))), [Dict(x => a(), y => a(), z => b())]),
                (f(a(), q(p(a(), b()), p(c(), b()))), [Dict(x => a(), y => b(), z => c())]),
                (f(b(), q(p(a(), b()), p(c(), b()))), []),
            ]
        ),
    ],
]

@testset "$set" for (set, tests) ∈ TESTS
    @testset "$pattern" for (pattern, cases) ∈ tests
        m = Terms.compile(pattern)
        @testset "$term" for (term, ms) ∈ cases
            matches = Terms.match(m, term)
            @test Set(matches) == Set(matches)  # immutability of iterator
            @test Set(matches) == Set(ms)
        end
    end
end
