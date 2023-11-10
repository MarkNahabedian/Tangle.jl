
@testset "Reidermeister Twist" begin
    loop = Loop()
    loop, handle = grab(loop, before(loop, :north), -1, :handle)
    new_loop, op = reidemeisterTwist(loop, handle, RightTwist())
    @test op isa ReidermeisterTwist
    @test op.sequence == 3
    @test op.from_loop == loop
    @test op.handle == handle
    @test op.twist isa RightTwist
    @test length(Tangle.crosspoints(new_loop)) == 1
    # TODO: Verify new points of interest are present.
end

