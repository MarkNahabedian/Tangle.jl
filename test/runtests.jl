using Tangle
using Test
using LinearAlgebra

@testset "Vector Utils" begin
    @test unit_vector(Vec3(5, 0, 0)) == Vec3(1, 0, 0)
    @test unit_vector(Vec3(0, 2, 0)) == Vec3(0, 1, 0)
    @test unit_vector(Vec3(0, 0, 4)) == Vec3(0, 0, 1)
    @test distance(Vec3(1, 1, 0), Vec3(2, 2, 0)) == sqrt(2)
end

@testset "Strand Tests" begin
    strand = Strand(label="foo")
    addPoint!(strand, Tangle.Shape(), 0, 0, 0, 0)
    addPoint!(strand, Tangle.Shape(), 1, 4, 1, 0)
    addPoint!(strand, Tangle.Shape(), 2, 4, 3, 1)
    addPoint!(strand, Tangle.Shape(), 4, 0, 0, 0.5)
    addPoint!(strand, Tangle.Shape(), -1, -2, 0, 0)
    addPoint!(strand, Tangle.Shape(), 5, -2, 1, 1)
    @test spmatch(find(strand, 2), StrandPoint(2, 4, 3, 1))
    @test find(strand, 3) == nothing
    @test find(strand, 6) == nothing
    @test find(strand, -2) == nothing
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
    @test spmatch(n2[1], StrandPoint(1, 4, 1, 0))
    @test spmatch(n2[2], StrandPoint(4, 0, 0, 0.5))
    @test spmatch(n2[3], StrandPoint(2, 4, 3, 1))
    n0 = nearest(strand, 0)
    @test spmatch(n0[1], StrandPoint(-1, -2, 0, 0))
    @test spmatch(n0[2], StrandPoint(1, 4, 1, 0))
    n3 = nearest(strand, 3)    
    @test spmatch(n3[1], StrandPoint(2, 4, 3, 1))
    @test spmatch(n3[2], StrandPoint(4, 0, 0,0.5))
    @test n3[3] == nothing
    n5 = nearest(strand, 5)
    @test spmatch(n5[1], StrandPoint(4, 0, 0, 0.5))
    @test n5[2] == nothing
    n_1 = nearest(strand, -1)
    @test n_1[1] == nothing
    @test spmatch(n_1[2], StrandPoint(0, 0, 0, 0))
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
    addPoint!(strand, Tangle.Shape(), 1, 0, 0, -1)
    addPoint!(strand, Tangle.Shape(), 2, 0, 2, -1)
    addPoint!(strand, Tangle.Shape(), 3, 2, 2, 1)
    addPoint!(strand, Tangle.Shape(), 4, 2, 0, 1)
    @test spmatch(center(strand.points...), StrandPoint(2.5, 1.0, 1.0, 0.0))
end

@testset "pointAt" begin
    strand = Strand()
    addPoint!(strand, Tangle.Shape(), 0, 0, 10, 0)
    addPoint!(strand, Tangle.Shape(), 10, 10, 00, 2)
    @test spmatch(first(pointAt(strand, 2)), StrandPoint(2, 2.0, 8.0, 0.4))
    @test spmatch(first(pointAt(strand, 5)), StrandPoint(5, 5.0, 5.0, 1.0))
    addPoint!(strand, Tangle.Shape(), 5, 5, 5, 1)
    p1, p2, p3 = pointAt(strand, 5)
    @test spmatch(p1, StrandPoint(5, 5, 5, 1))
end

@testset "Reidermeister Twist" begin
    strand = Strand(label="foo")
    head = addPoint!(strand, Tangle.Shape(), 1, 0, 0, 0)
    tail = addPoint!(strand, Tangle.Shape(), 13, 10, 0, 0)
    between = addPoint!(strand, Tangle.Shape(), 7, 5, 0, 0)
    # Right hand twist:
    rh1, rh2 = reidermeisterTwist(strand, 4)
    # Right handed: second crosspoint is above first:
    @test rh1.z < rh2.z
    # The loop that's formed by reidermeisterTwist has two dianeters:
    diameter1 = (center(rh1, rh2),
                 first(pointAt(strand, 4)))
    diameter2 = (first(pointAt(strand, 3)),
                 first(pointAt(strand, 5)))
    # The diameter of the loop should be DEFAULT_LOOP_DIAMETER:
    @test distance(diameter1...) == DEFAULT_LOOP_DIAMETER
    @test distance(diameter2...) == DEFAULT_LOOP_DIAMETER
    # Points at 2, 3, 4, 5, 6 should project to a circle in the x,y
    # plane:
    @test center(diameter1...) == center(diameter2...)
    # euclidean distance between 2 and 6 should correspond to gap
    @test distance(Vec3(rh1), Vec3(rh2)) ==
        strand.thickness * DEFAULT_CROSSING_GAP
    # Left hand twist:
    lh1, lh2 = reidermeisterTwist(strand, 10, handedness=LeftHanded())
    # Left handed: second crosspoint is below first:
    @test lh1.z > lh2.z
    # The loop that's formed by reidermeisterTwist has two dianeters:
    diameter3 = (center(lh1, lh2),
                 first(pointAt(strand, 10)))
    diameter4 = (first(pointAt(strand, 9)),
                 first(pointAt(strand, 11)))
    # The diameter of the loop should be DEFAULT_LOOP_DIAMETER:
    @test distance(diameter3...) == DEFAULT_LOOP_DIAMETER
    @test distance(diameter4...) == DEFAULT_LOOP_DIAMETER
    # Points at 8, 9, 10, 11, 12 should project to a circle in the x,y
    # plane
    @test center(diameter3...) == center(diameter4...)
    # euclidean distance between 8 and 12 should correspond to gap
    @test distance(Vec3(lh1), Vec3(lh2)) ==
        strand.thickness * DEFAULT_CROSSING_GAP
end

