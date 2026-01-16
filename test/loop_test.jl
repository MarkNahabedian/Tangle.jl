
@testset "Default Loop" begin
    loop = Loop()
    @test length(loop.poi) == 5
    @test length(operations(loop)) == 1
    @test Tangle.next_operation_sequence_number(loop) == 2
end

@testset "find_poi" begin
    loop = Loop()
    @test length(loop.poi) == 5
    @test find_poi(poi -> poi.label == :west, loop).label == :west
    @test find_poi(poi -> poi.p == KnotParameter(0.5),loop).label == :west
end

@testset "AddPOI" begin
    loop = Loop()
    east = find_poi(poi -> poi.label == :east, loop)
    north = find_poi(poi -> poi.label == :north, loop)
    ne = (east.p + north.p) / 2
    op = AddPOI(loop, ne, :northeast)
    loop = op()
    @test length(loop.poi) == 6
    map(poi -> poi.label, loop.poi) ==
        [ :east, :northeast, :north, :west, :south, :closed ]
end

@testset "next/previous in Loop" begin
    loop = Loop()
    @test length(loop.poi) == 5
    @test next(loop, typemin(KnotParameter)).label == :north
    @test previous(loop, typemax(KnotParameter)).label == :south
    # Test wrap-around:
    @test next(loop, typemax(KnotParameter)).label == :east
    @test previous(loop, typemin(KnotParameter)).label == :closed
end

@testset "LoopSegmentsIterator" begin
    loop = Loop()
    nxt = nothing
    count = length(loop.poi)
    for (s1, s2) in LoopSegmentsIterator(loop)
        @test count > 0
        if count <= 0
            break
        end
        @test s1 != s2
        @test s2.p == next(loop, s1).p
        @test s2.label == next(loop, s1).label
        @test s2 == next(loop, s1)
        @test s1.p == previous(loop, s2).p
        if nxt != nothing
            @test nxt == s1
        end
        nxt = s2
        count -= 1
    end
end

