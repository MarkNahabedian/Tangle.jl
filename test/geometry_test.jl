using Tangle: Line, direction_vector, parallel,
    point_on_line, point_in_segment, proximal_points

@testset "Line tests" begin
    @test direction_vector(Line([-2, -2, -2], [1, 1, 1])) ==
        [3, 3, 3]
    @test Line([0, 0, 0], [4, 4, 4])(0.25) == [1, 1, 1]
    @test parallel(Line([0, 0, 0], [1, 1, 1]),
                   Line([1, 0, 0], [2, 1, 1])) == true
    @test parallel(Line([0, 0, 0], [1, 1, 1]),
                   Line([2, 1, 1], [1, 0, 0])) == true
    let
        p1 = [1, 1, 1]
        d = [2, 4, 6]
        line = Line(p1, p1 + 2 * d)
        @test point_on_line(p1 + d, line)
        @test point_on_line(p1 - d, line)
        @test point_on_line(p1 + 3 * d, line)
        @test !point_on_line(p1 + d - [0, 0, 1], line)
        @test point_in_segment(p1 + d, line) == 0.5
        @test point_in_segment(p1 + 3 * d, line) == nothing
    end
end

@testset "proximal_points" begin
    @test proximal_points(Line([-2, 0, 0], [2, 0, 0]),
                          Line([0, -2, 0], [0, 2, 0])) ==
                              (
                                  [0, 0, 0],
                                  [0, 0, 0]
                              )
    @test proximal_points(Line([-2, 0, 0], [2, 0, 0]),
                          Line([0, -2, 1], [0, 2, 1])) ==
                              (
                                  [0, 0, 0],
                                  [0, 0, 1]
                              )
    @test proximal_points(Line([0, 0, 0], [4, 4, 0]),
                          Line([0, 4, 1], [4, 0, 1])) ==
                              (
                                  [2, 2, 0],
                                  [2, 2, 1]
                              )
end

