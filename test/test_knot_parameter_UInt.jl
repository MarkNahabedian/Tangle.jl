using InteractiveUtils

@testset "KnotParameter" begin
    # Consider the subtypes of Unsigned in ascending order of size:
    # We get InexactError for UInt64.
    st = sort(subtypes(Unsigned); by = t -> typemax(t))[1:end-1]
    for T in st
        @test zero(T) == 0
    end
    for T in st
        @test typemin(KnotParameterN{T}).p == typemin(T)
    end
    #=
    for T in filter(t -> ! in(t, [UInt64, UInt128]), st)
        @test KnotParameterN{T}(0.5).p == round(T, 0.5 * (1 + BigInt(typemax(T))))
    end
    =#
    for T in st
        @test zero(KnotParameterN{T}).p == 0
    end
    #=
    for T in st
        @test KnotParameterN{T}(0.5) == KnotParameterN{T}(1//2)
        @test 2 * KnotParameterN{T}(0.5) == KnotParameterN{T}(0)
    end
    =#
    for T in st
        @test (typemax(KnotParameterN{T}) + KnotParameterN{T}(1)).p == zero(T)
    end
    for T in st
        @test KnotParameterN{T}(-6) + KnotParameterN{T}(10) == KnotParameterN{T}(4)
    end
    for T in st
        @test 2 * KnotParameterN{T}(2//3) == (KnotParameterN{T}(2//3) + KnotParameterN{T}(2//3))
    end
    for T in st
        @test KnotParameterN{T}(1//3) * 3 == zero(KnotParameterN{T})
    end
    for T in st
        @test KnotParameterN{T}(2//3) // 3 == KnotParameterN{T}(2//9)
    end
    for T in st
        @test KnotParameterN{T}(2//9) // 1//3 == KnotParameterN{T}(2//3)
    end
    for T in st
        @test zero(KnotParameterN{T}) // 2 == KnotParameterN{T}(1//2)
    end
    for T in st
        if T != UInt64
            @test convert(Rational{Int}, KnotParameterN{T}(1//4)) == 1//4
        end
        # @test convert(Float64, KnotParameterN{T}(0.25)) == 0.25
    end
    for T in st
        @test KnotParameterN{T}(1//4) - KnotParameterN{T}(3//4) == KnotParameterN{T}(1//2)
    end
    for T in st
        let
            from = KnotParameterN{T}(6//10)
            to = KnotParameterN{T}(4//10)
            kps = divide_interval(from, to, 3)
            @test length(kps) == 3
            @test kps == [ KnotParameterN{T}(8//10),
                           KnotParameterN{T}(0//10),
                           KnotParameterN{T}(2//10) ]
        end
    end
end

