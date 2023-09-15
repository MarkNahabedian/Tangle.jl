export grab

struct Grab <: Operation
    sequence::Integer     # Every Operation has a sequence number.
    from_loop::Loop       # EveryOperation records the original Loop
                          # on which the operation was applied.
    at::KnotParameter     # The KnotParameter grabbed from.
    delta                 # how far the grab operation pulled at at.

    Grab(from_loop, at, delta) =
        new(next_operation_sequence_number(from_loop),
            from_loop, at, delta)
end


"""
    was(::Grab)

Return the PointOfInterest that this operation grabbed from.
"""
was(op::Grab) = op.from_loop(op.at)


"""
    grab(loop::Loop, at::KnotParameter, delta, label::Symbol)

Return a new loop with a point of interest added between the one
labeled `after` and the next point of interest after it.

The new point of interest will be displaced by delta "outward".

`label` provides a way to label or explain the reason for grabbing.
"""
function grab(loop::Loop, after::Symbol, delta, label::Symbol)
    after_kp = find_poi(loop) do poi
        poi.label == after
    end.p
    next_after_kp = next(loop, after_kp).p
    at = (after_kp + next_after_kp) / 2
    grab(loop, at, delta, label::Symbol)
end


"""
    grab(::Loop, ::KnotParameter, label, delta)

Return a new Loop with a point of interest added at the specified
KnotParameter with the specified symbol.

The new point of interest will be displaced by delta "outward".

`label` provides a way to label or explain the reason for grabbing.
"""
function grab(loop::Loop, at::KnotParameter, delta, label::Symbol)
    if at in map(poi -> poi.p, loop.poi)
        error("Loop already has activity at $at")
    end
    op = Grab(loop, at, delta)
    # spatial coordinates of some points we use for construction:
    # points on either side of at:
    p1 = loop((at + previous(loop, at).p) / 2)
    p2 = loop((at + next(loop, at).p) / 2)
    midpoint = center(p1, p2)
    point = loop(at)
    loopcenter = center(loop)
    # The new point will be dispaced from point by delta in a
    # direction that is
    # 1) perpendiculaer to the line p1, p2, and
    # 2) coplanar with p1, p2 and loopcenter.
    projection = let
        # Project point onto the line p1, p2:
        # See https://gamedev.stackexchange.com/questions/72528/how-can-i-project-a-3d-point-onto-a-3d-line
        point_p1 = point - p1
        p2_p1 = p2 - p1
        dot(v1, v2) = reduce(+, v1 .* v2)
        p1 + p2_p1 * dot(p2_p1, point_p1) / dot(p2_p1, p2_p1)
    end
    displacement = delta * unit_vector(point - projection)
    new_poi = PointOfInterest(at,
                              (point + displacement)...,
                              label, op)
    poi = [ loop.poi..., new_poi ]
    return Loop(poi), new_poi
end

