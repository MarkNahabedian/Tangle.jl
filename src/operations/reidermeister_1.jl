
export reidemeisterTwist, RightTwist, LeftTwist

abstract type Twist end
struct RightTwist <: Twist end
struct LeftTwist <: Twist end
multiplier(::RightTwist) = 1
multiplier(::LeftTwist) = -1


struct ReidermeisterTwist <: Operation
    sequence::Integer
    from_loop::Loop
    handle::PointOfInterest
    twist::Twist

    ReidermeisterTwist(from_loop, at, twist) =
        new(next_operation_sequence_number(from_loop),
            from_loop, at, twist)
end


CROSSPOINT_SEPARATION = Float16(0.1)


"""
   reidemeisterTwist(loop::Loop, handle::PointOfInterest, twist::Twist)

Return a new loop by applying the Reidermeister I (twist) operation to
loop at `handle`.  `twist` determines the direstion of twist.

`handle` should be the resulkt of a grab operation.
"""
function reidemeisterTwist(loop::Loop, handle::PointOfInterest, twist)
    op = ReidermeisterTwist(loop, handle, twist)
    grab = spatial_coordinates(was(handle.operation))
    hc = spatial_coordinates(handle)
    loop_center = center(grab, hc)
    radius_vector = hc - loop_center
    loop_radius = distance(radius_vector)
    prev_poi = previous(loop, handle)
    next_poi = next(loop, handle)
    prev_point = unit_vector(spatial_coordinates(prev_poi))
    up_vector = cross(radius_vector, prev_point - hc)
    lateral = unit_vector(cross(up_vector, radius_vector))
    p1 = loop_center - loop_radius * lateral
    p2 = loop_center + loop_radius * lateral
    crosspoint = loop_center - radius_vector
    n = up_vector * CROSSPOINT_SEPARATION * multiplier(twist) / 2
    # New points of interest:
    # Points of interest, in order, should be
    # prev_poi, +crosspoint_1, +r1loop1, handle, +r1loop2, +crosspoint_2, next_poi
    c1, l1 = divide_interval(prev_poi.p, handle.p, 2)
    l2, c2 = divide_interval(handle.p, next_poi.p, 2)
    crosspoint_1 = PointOfInterest(c1, (crosspoint + n)...,
                                   :r1_crosspoint_1, op, true)
    crosspoint_2 = PointOfInterest(c2, (crosspoint - n)...,
                                   :r1_crosspoint_2, op, true)
    # These two points give the loop some shape:
    r1loop1 = PointOfInterest(l1, p1..., :r1loop1, op, false)
    r1loop2 = PointOfInterest(l2, p2..., :r1loop2, op, false)
    return Loop([ r1loop1, crosspoint_1, crosspoint_2, r1loop2,
                  loop.poi... ]), op
end

