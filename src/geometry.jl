using LinearAlgebra
using Symbolics
using Symbolics: variable, substitute, solve_for

# We can represent a point as a three element Julia Vector.

# We also represent a vector as a three element Julia Vector.


"""
A Line is represented by two points on it.
For a line segment, these points are the end points.
"""
struct Line
    point1::Vector
    point2::Vector
end

direction_vector(line::Line) = line.point2 - line.point1

function unit_direction_vector(line::Line)
    dv = direction_vector(line)
    dv / norm(dv)
end


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
A Line can be treated as a parametric function to identify
some point on the line.
"""
function (line::Line)(parameter)::Vector
    line.point1 + parameter * direction_vector(line)
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
    r_solved, s_solved = solve_for([dot1, dot2], [r, s])
    return line1(r_solved), line2(s_solved)
end

