using LinearAlgebra
using Symbolics
import GeometryBasics
using Symbolics: variable, substitute, symbolic_linear_solve

# Our representation of a Point in 3 space:
const Point = GeometryBasics.Point{3, Real}

# Sumbractiing two GeometryBasics.Points gives another
# GeometryBasics.Point, rather than something that is semantically a
# vector.  Sigh.


"""
A Line is represented by two points on it.
For a line segment, these points are the end points.
"""
const Line = GeometryBasics.Line{3, Real}
Line(point1::Point, point2::Point) = Line([point1, point2])
Line(point1::Vector{<:Real}, point2::Vector{<:Real}) =
    Line([Point(point1...), Point(point2...)])
Base.getproperty(line::Line, ::Val{:point1}) = line.points[1]
Base.getproperty(line::Line, ::Val{:point2}) = line.points[2]
@property_trampolines Line


"""
    direction_vector(::Line)

Return a direction vector for the `Line`.
"""
direction_vector(line::Line) = line.point2 - line.point1


"""
    unit_direction_vector(::Line)

Return the unit direction vector for the `Line`.
"""
unit_direction_vector(line::Line) =
    unit_vector(direction_vector(line))


"""
A Line can be treated as a parametric function to identify
some point on the line.
"""
(line::Line)(parameter::Real)::Vector =
    line.point1 + parameter * direction_vector(line)


"""
    parallel(line1::Line, line2::Line)::Bool

Return true if the two lines are parallel.
"""
function parallel(line1::Line, line2::Line)::Bool
    udv1 = unit_direction_vector(line1)
    udv2 = unit_direction_vector(line2)
    udv1 == udv2 || udv1 == -udv2
end


"""
    point_on_line(point, line::Line)::Bool

Return true if `line` intersects `point`.
"""
function point_on_line(point, line::Line)::Bool
    d1 = unit_direction_vector(line)
    d2 = unit_vector(point - line.point1)
    d1 == d2 || d1 == - d2
end


"""
    parameter_for_point(line::Line, point)

Iff `point` is on `line`, returns the `parameter` for `line` such that
`line(parameter) == point`.
"""
function parameter_for_point(line::Line, point)
    p = (point - line.point1) ./ 
        (line.point2 - line.point1)
    if all(x -> x == p[1], p)
        return p[1]
    end
end


"""
    point_in_segment(point, segment::Line)

If `point` is on the specified `Line` and lies within the
defining points of that `Line` then return the parameter
`p` such that `line(p) == point`, otherwise return nothing.
"""
function point_in_segment(point, segment::Line)
    s = parameter_for_point(segment, point)
    if s == nothing
        return nothing
    end
    if s >= 0.0 && s <= 1.0
        return s
    end
    return nothing
end


"""
    proximal_points(line1::Line, line2::Line)

Return the two points (as 3 element Vectors) which are the point on
line1 closest to line2 and the point on line2 closest to line1
respectively.
"""
function proximal_points(line1::Line, line2::Line)
    if parallel(line1, line2)
        error("$line1 and $line2 are parallel.")
    end
    # Symbolic parametric formulas for the two lines
    @variables r, s
    spf1 = line1(r)
    spf2 = line2(s)
    # A vector between a point on line1 and a point on line 2:
    v = spf2 - spf1
    # for the closest points, v is perpendicular to both lines:
    dot1 = Equation(0, dot(v, direction_vector(line1)))
    dot2 = Equation(0, dot(v, direction_vector(line2)))
    r_solved, s_solved = symbolic_linear_solve([dot1, dot2], [r, s])
    return line1(Symbolics.value(r_solved)), line2(Symbolics.value(s_solved))
end

