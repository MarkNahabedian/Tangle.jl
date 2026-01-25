using InteractiveUtils

@testset "KnotParameter" begin
    @test zero(KnotParameter).p == 0
    @test typemin(KnotParameter).p == 0
    let
        tm = typemax(KnotParameter)
        infinitessimal = Rational(1 // typemax(Int))
        @test tm.p == 1 - infinitessimal
        @test tm + KnotParameter(infinitessimal) == zero(KnotParameter)
    end
    @test KnotParameter(-1//3) + KnotParameter(2//3) == KnotParameter(1//3)
    @test 2 * KnotParameter(2//3) == (KnotParameter(2//3) + KnotParameter(2//3))
    @test KnotParameter(1//3) * 3 == zero(KnotParameter)
    @test KnotParameter(2//3) // 3 == KnotParameter(2//9)
    @test KnotParameter(2//9) // (1//3) == KnotParameter(2//3)
    @test KnotParameter(1//4) - KnotParameter(3//4) == KnotParameter(1//2)
    let
        from = KnotParameter(6//10)
        to = KnotParameter(4//10)
        kps = divide_interval(from, to, 3)
        @test length(kps) == 3
        @test kps == [ KnotParameter(8//10),
                       KnotParameter(0//10),
                       KnotParameter(2//10) ]
    end
end

