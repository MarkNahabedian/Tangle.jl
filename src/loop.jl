using CubicSplines
using Printf

export Loop, Operation, operations, InitializeLoop
export PointOfInterest, coordinates, spatial_coordinates, find_poi, next, previous
export grab


abstract type Operation
# Evert Operation should have a field named "sequence" field that is
# unique within a given Loop.
end


"""
    PointOfInterest

PointOfInterest represents a point on a `Loop` for which a location
has been spoecified.

No two points of interest should have the same KnotParameter widthin a
Loop.

No two points of interest should have equal coordinates within the
same mathematical link.
n
Currently, no code enforces these rules.
"""
@Base.kwdef struct PointOfInterest
    p::KnotParameter
    # Should we use cylindrical coordinates instead?  Nah, there's
    # symetry in cartesean coordinates.
    x::AbstractFloat
    y::AbstractFloat
    z::AbstractFloat
    label
    operation::Operation
    is_crosspoint::Bool = false
end

PointOfInterest(p::KnotParameter,
                x::AbstractFloat, y::AbstractFloat, z::AbstractFloat,
                label, operation::Operation) =
                    PointOfInterest(p, x, y, z, label, operation, false)


const PointsOfInterest = Vector{PointOfInterest}

Base.sort(poi::PointsOfInterest) = sort(poi; by = poi -> poi.p)

coordinates(poi::PointOfInterest) =
    [ poi.p, poi.x, poi.y, poi.z ]

spatial_coordinates(poi::PointOfInterest) =
    [ poi.x, poi.y, poi.z ]

function spatial_coordinates(point::Vector)
    # ??? Should we verify the element types?
    if length(point) == 3
        return point
    else
        return point[2:end]
    end
end


"""
    Loop

A Loop represents a mathematical knot.

In one sense, it is a function in some parameter `p` (a KnotParameter)
that returns a point in R3 for `p`.

```
loop(0.0) == loop(1.0)
```

where `loop` is a `Loop`.

As a means of defining and representing knots, a Loop has a sorted
set of "points of interest".  Each point of interest is just a
specific value for the parameter `t`.
"""
struct Loop
    poi::PointsOfInterest    # points of interest
    # We cache the knot function here
    knot_function

    function Loop()
        op = InitializeLoop()
        # We define some points of interest to give the Loop an
        # initial shape:
        Loop([
            PointOfInterest(KnotParameter(0.0),   1.0,  0.0, 0.0, :east, op),
            PointOfInterest(KnotParameter(0.25),  0.0,  1.0, 0.0, :north, op),
            PointOfInterest(KnotParameter(0.5),  -1.0,  0.0, 0.0, :west, op),
            PointOfInterest(KnotParameter(0.75),  0.0, -1.0, 0.0, :south, op),
            # CubicSplines needs at least 5 data points:
            PointOfInterest(MAX_KnotParameter,  1.0,  0.0, 0.0, :closed, op)
        ])
    end
    
    function Loop(poi::PointsOfInterest)
        poi = sort(poi)
        values(fieldname) = map(p -> getfield(p, fieldname), poi)
        # ??? Do we need to explicitly repeat the first PointOfInterest?
        p = map(p -> p.p, values(:p))
        x = CubicSpline(p, values(:x))
        y = CubicSpline(p, values(:y))
        z = CubicSpline(p, values(:z))
        new(poi, at -> [ x(at.p), y(at.p), z(at.p) ])
    end
end


next_operation_sequence_number() = 1

next_operation_sequence_number(loop::Loop) =
    something(maximum(loop.poi) do poi
                  something(poi.operation.sequence + 1, -1)
              end,
              1)

struct InitializeLoop <:Operation
    sequence

    InitializeLoop() = new(next_operation_sequence_number())
end


center(points::Vector{<:Real}...) =
    reduce(+, points) / length(points)

center(loop::Loop) =
    center(map(spatial_coordinates, loop.poi)...)


struct Crosspoint
    in::PointOfInterest
    out::PointOfInterest

    function Crosspoint(in::PointOfInterest, out::PointOfInterest)
        @assert in.p < out.p
        @assert in.is_crosspoint
        @assert out.is_crosspoint
        @assert in.operation == out.operation
        new(in, out)
    end
end

operation(cp::Crosspoint) = cp.in.operation



"""
    (::Loop)(at)

Return a three element vector of the X, Y and Z coordinates of the
point of the Loop corresponding to `at'.

This function should be continuous and defined by the specified points
of interest.
"""
function (loop::Loop)(p::KnotParameter)
    loop.knot_function(p)
end


"""
    find_poi(predicate, ::Loop)

Return the `PointOfInterest` from the Loop which satisfies `predicate.
"""
function find_poi(predicate, loop::Loop)
    i = findfirst(predicate, loop.poi)
    if i == nothing
        return nothing
    end
    loop.poi[i]
end


"""
   next(loop::Loop, kp::KnotParameter)

If `kp` is the KnotParameter of some `PointOfInterest` in `loop` then
return the next `PointOfInterest` in that `loop`.
"""
function next(loop::Loop, kp::KnotParameter)
    i = findfirst(loop.poi) do poi
        poi.p > kp
    end
    if i == nothing
        # Wrap around
        return loop.poi[1]
    end
    return loop.poi[i]
end


"""
   previous(loop::Loop, kp::KnotParameter)

If `kp` is the KnotParameter of some `PointOfInterest` in `loop` then
return the next `PointOfInterest` in that `loop`.  Otherwise, return
`nothing`.
"""
function previous(loop::Loop, kp::KnotParameter)
    i = findlast(loop.poi) do poi
        poi.p < kp
    end
    if i == nothing
        # wrap around
        return loop.poi[lastindex(loop.poi)]
    end
    return loop.poi[i]
end

next(loop::Loop, poi::PointOfInterest) = next(loop, poi.p)
previous(loop::Loop, poi::PointOfInterest) = previous(loop, poi.p)


function operations(loop::Loop)
    found = Set()
    for poi in loop.poi
        if poi.operation != nothing
            push!(found, poi.operation)
        end
    end
    sort(collect(found); by = o -> o.sequence)
end


function crosspoints(loop::Loop)
    d = DefaultDict{Operation, Vector{PointOfInterest}}()
    for poi in loop.poi
        if poi.is_crosspoint
            push!(d[poi.operation], poi)
        end
    end
    crosspoints = Vector{Crosspoint}()
    for cp in values(d)
        @assert length(cp) == 2
        @assert cp[1].p < cp[2].p
        push!(crosspoints, Crospoint(cp...))
    end
    crosspoints
end


distance(v) = sqrt(reduce(+, (map(n -> n^2, v))))

function unit_vector(v)
    v / distance(v)
end

function cross(a, b)
    [
    a[2] * b[3] − a[3] * b[2],
    a[3] * b[1] − a[1] * b[3],
    a[1] * b[2] − a[2] * b[1]
    ]
end


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


################################################################################

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

################################################################################
