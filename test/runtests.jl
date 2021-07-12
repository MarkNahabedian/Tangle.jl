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
    n2 = nearest(strand, 2)
    @test n2[1] == StrandPoint(1, 4, 1, 0)
    @test n2[2] == StrandPoint(4, 0, 0, 0.5)
    n0 = nearest(strand, 0)
    @test n0[1] == StrandPoint(-1, -2, 0, 0)
    @test n0[2] == StrandPoint(1, 4, 1, 0)
    n3 = nearest(strand, 3)    
    @test n3[1] == StrandPoint(2, 4, 3, 1)
    @test n3[2] == StrandPoint(4, 0, 0,0.5)
    n5 = nearest(strand, 5)
    @test n5[1] == StrandPoint(4, 0, 0, 0.5)
    @test n5[2] == nothing
    n_1 = nearest(strand, -1)
    @test n_1[1] == nothing
    @test n_1[2] == StrandPoint(0, 0, 0, 0)
end

@testset "Max Thickness" begin
    strands = [ Strand(thickness=1),
                Strand(thickness=2),
                Strand(thickness=1)
                ]
    @test maxThickness(strands...) == 2
end

@testset "StrandPoints center" begin
    strand = Strand()
    addPoint(strand, 1, 0, 0, -1)
    addPoint(strand, 2, 0, 2, -1)
    addPoint(strand, 3, 2, 2, 1)
    addPoint(strand, 4, 2, 0, 1)
    @test center(strand.points) == StrandPoint(2.5, 1.0, 1.0, 0.0)
end

@testset "pointAt" begin
    strand = Strand()
    addPoint(strand, 0, 0, 10, 0)
    addPoint(strand, 10, 10, 00, 2)
    @test pointAt(strand, 2) == StrandPoint(2, 2.0, 8.0, 0.4)
    @test pointAt(strand, 5) == StrandPoint(5, 5.0, 5.0, 1.0)
end

@testset "Reidermeister Twist" begin
    strand = Strand(label="foo")
    head = addPoint(strand, 0, 0, 0, 0)
    tail = addPoint(strand, 10, 10, 0, 0)
    between = addPoint(strand, 5, 5, 0, 0)
    # Right hand twist:
    rh1, rh2 = reidermeisterTwistRight(strand, 2, 3, 0)
    rhloop = addPoint(strand, (rh1.p + rh2.p) / 2, 2, 0, 0)
    @test nearest(strand, rhloop.p) == (rh1, rh2)
    @test nearest(strand, rh1.p) == (head, rhloop)
    # Left hand twist:
    println("POINTS: ", strand.points)
    lh1, lh2 = reidermeisterTwistLeft(strand, 8, 3, 0)
    @test nearest(strand, rh2.p) == (rhloop, between)
    lhloop = addPoint(strand, (lh1.p + lh2.p) / 2, 8, 0, 0)
    # *** I should think about why these are swapped?  Handedness?
    @test nearest(strand, lhloop.p) == (lh2, lh1)
    # *** I should think about why these are swapped?  Handedness?
    @test nearest(strand, lh1.p) == (lhloop, tail)
    @test nearest(strand, lh2.p) == (between, lhloop)
end

