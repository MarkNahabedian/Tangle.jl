using Tangle
using Test

@testset "Strand Tests" begin
    strand = Strand(label="foo")
    addPoint(strand, 0, 0, 0, 0)
    addPoint(strand, 1, 4, 1, 0)
    addPoint(strand, 2, 4, 3, 1)
    addPoint(strand, 4, 0, 0, 0.5)
    addPoint(strand, -1, -2, 0, 0)
    addPoint(strand, 5, -2, 1, 1)
    b = bounds(strand)
    @test b.minP == -1
    @test b.maxP == 5
    @test b.minX == -2
    @test b.maxX == 4
    @test b.minY == 0
    @test b.maxY == 3
    @test b.minZ == 0
    @test b.maxZ == 1
    n0 = nearest(strand, 0)
    @test n0[1] == StrandPoint(0, 0, 0, 0)
    @test n0[2] == StrandPoint(0, 0, 0, 0)
    n3 = nearest(strand, 3)    
    @test n3[1] == StrandPoint(2, 4, 3, 1)
    @test n3[2] == StrandPoint(4, 0, 0,0.5)
end
