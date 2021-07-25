
@testset "Chain" begin
    head = Link(0, 0, 0)
    @test link_count(head) == 1
    @test next_count(head) == 0
    @test previous_count(head) == 0
    head.anchored = true
    length = 5
    tail = Link(length, 0, 0)
    tail.anchored = true
    chain(head, tail)
    @test previous_count(head) == 0
    @test next_count(tail) == 0
    @test next_count(head) == previous_count(tail) == length
    @test link_count(head) == length + 1
end
