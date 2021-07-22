# Reidermeister moves.

export Handedness, RightHanded, LeftHanded, multiplier
export reidermeisterTwist


abstract type Handedness end
struct RightHanded <: Handedness end
struct LeftHanded <: Handedness end

multiplier(::RightHanded) = 1
multiplier(::LeftHanded) = -1

"""
    reidermeisterTwist(strand, p; axis, handedness, gap, loop_diameter)
Form a Reidermeister 1 twist in `strand`.
The strand will cross itself at parameter p then loop around axis with
the specified diameter.
"""
function reidermeisterTwist(strand::Strand, p;
                            axis = [0, 0, 1],
                            handedness = RightHanded(),
                            gap = DEFAULT_CROSSING_GAP,
                            loop_diameter = DEFAULT_LOOP_DIAMETER)
    at, before, after = pointAt(strand, p)
    direction = unit_vector(Vec3(before, after))
    # We will at two points for the crossing and three more points to
    # form a circular loop.  These are the parameter values for tthose
    # points:
    pvalues = before.p .+ (collect(1:5) * ((after.p - before.p) / 6))
    sideways = unit_vector(LinearAlgebra.cross(Vec3(before, after), axis))
    loop = Vec3(at) + loop_diameter * sideways
    addPoint!(strand, Shape(), pvalues[3], loop...)
    loop_center = (Vec3(at) + loop) / 2
    addPoint!(strand, Shape(), pvalues[2],
             (loop_center + (direction * (loop_diameter / 2)))...)
    addPoint!(strand, Shape(), pvalues[4],
             (loop_center - (direction * (loop_diameter /2)))...)
    gap_vector = multiplier(handedness) * (gap / 2) * maxThickness(strand) * axis
    cp1 = addPoint!(strand, Form(), pvalues[1], (Vec3(at) - gap_vector)...)
    cp2 = addPoint!(strand, Form(), pvalues[5], (Vec3(at) + gap_vector)...)
    return cp1, cp2
end
