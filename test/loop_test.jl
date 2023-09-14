
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

@testset "next/previous in Loop" begin
    loop = Loop()
    @test length(loop.poi) == 5
    @test next(loop, MIN_KnotParameter).label == :north
    @test previous(loop, MAX_KnotParameter).label == :south
    # Test wrap-around:
    @test next(loop, MAX_KnotParameter).label == :east
    @test previous(loop, MIN_KnotParameter).label == :closed
end

