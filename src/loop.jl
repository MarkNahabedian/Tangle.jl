using CubicSplines
using Printf

export Loop, operations, InitializeLoop, find_poi
export next, previous, before, after
export LoopSegmentsIterator


# Maybe rename Loop to Cord or Rope and specify locations for its endpoints.
# Endpoints would default to the same point.
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


"""
    center(points)

Return the point at the center of the collection of points.
"""
function center end

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

Return the `PointOfInterest` from the Loop which satisfies `predicate`.
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


"""
    before(loop::Loop, label)
    before(loop::Loop, poi::PointOfInterest)::KnotParameter

Return a KnotParameter that comes before the specified
`PointOfInterest` but after any previous points of interest.
"""
function before end


"""
    after(loop::Loop, label)
    after(loop::Loop, poi::PointOfInterest)::KnotParameter

Return a KnotParameter that comes after the specified
`PointOfInterest` but before any succeeding points of interest.
"""
function after end


before(loop::Loop, label) =
    before(loop,
           find_poi(loop) do poi
               poi.label == label
           end)

before(loop::Loop, poi::PointOfInterest)::KnotParameter =
    divide_interval(previous(loop, poi).p, poi.p, 2)[1]

after(loop::Loop, label) =
    after(loop,
           find_poi(loop) do poi
               poi.label == label
           end)

after(loop::Loop, poi::PointOfInterest)::KnotParameter =
    divide_interval(poi.p, next(loop, poi).p, 2)[1]


"""
    LoopSegmentsIterator(::Loop)

Return an iterator for iterating over the segments of a Loop.

Each segment is a two element tuple of successive points of interest
of Loop.
"""
struct LoopSegmentsIterator
    loop::Loop
end


function Base.iterate(i::LoopSegmentsIterator)
    if length(i.loop.poi) < 1
        return nothing
    end
    (i.loop.poi[1], i.loop.poi[2]), i.loop.poi[2]
end

function Base.iterate(i::LoopSegmentsIterator, state::PointOfInterest)
    if state == i.loop.poi[1]
        # wrapped around.
        return nothing
    end
    n = next(i.loop, state)
    (state, n), n
end


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
    d = DefaultDict{Operation,
                    Vector{PointOfInterest}}(Vector{PointOfInterest}())
    for poi in loop.poi
        if poi.is_crosspoint
            push!(d[poi.operation], poi)
        end
    end
    crosspoints = Vector{Crosspoint}()
    for cp in values(d)
        @assert length(cp) == 2
        @assert cp[1].p < cp[2].p
        push!(crosspoints, Crosspoint(cp...))
    end
    crosspoints
end


