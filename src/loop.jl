using CubicSplines

export Loop, grab

abstract type Operaation end


"""
    PointOfInterest

PointOfInterest represents a point on a `Loop` for which a location
has been spoecified.

No two points of interest should have the same KnotParameter widthin a
Loop.

No two points of interest should have equal coordinates within the
same mathematical link.

Currently, no code enforces these rules.
"""
struct PointOfInterest
    p::KnotParameter
    # Should we use cylindrical coordinates instead?  Nah, there's
    # symetry in cartesean coordinates.
    x::AbstractFloat
    y::AbstractFloat
    z::AbstractFloat
    why
end

const PointsOfInterest = Vector{PointOfInterest}

Base.sort(poi::PointsOfInterest) = sort(poi; by = poi -> poi.p)



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
        # We define some points of interest to give the Loop an
        # initial shape:
        Loop([
            PointOfInterest(KnotParameter(0.0),   1.0,  0.0, 0.0, :east),
            PointOfInterest(KnotParameter(0.25),  0.0,  1.0, 0.0, :north),
            PointOfInterest(KnotParameter(0.5),  -1.0,  0.0, 0.0, :west),
            PointOfInterest(KnotParameter(0.75),  0.0, -1.0, 0.0, :south),
            PointOfInterest(MAX_KnotParameter,  1.0,  0.0, 0.0, :closed) ])
    end
    
    function Loop(poi)
        poi = sort(poi)
        values(fieldname) = map(p -> getfield(p, fieldname), poi)
        p = map(p -> p.p, values(:p))
        x = CubicSpline(p, values(:x))
        y = CubicSpline(p, values(:y))
        z = CubicSpline(p, values(:z))
        new(poi, p -> [ x(p.p), y(p.p), z(p.p) ])
    end
end


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

function unit_vector(v)
    sqrt(reduce(+, (map(n -> n*2, v))))
end


"""
    grab(::Loop, ::KnotParameter, why, delta)

    Return a new Loop with a point of interest added at the specified
    KnotParameter with the specified symbol.

    The new point of interest will be radialy bumped out from the
    origin by `delta`.

    `why` provides a way to label or explain the reason for grabbing.
"""
function grab(loop::Loop, p::KnotParameter, why::Symbol, delta)::Loop
    if p in map(poi -> poi.p, loop.poi)
        return loop
    end
    point = loop(p)
    uv = point / sqrt(reduce(+, map(n -> n^2, point)))
    poi = [ loop.poi...,
            PointOfInterest(p,
                                (point + delta * uv)...,
                            why)
            ]
    Loop(poi)
end


"""
    neighbors(loop::Loop, at)

Return the greatest parameter from loop's points of interest that is
less than `at` and the least parameter that is greater than `at`.  0.0
and 1.0 serve as default values if there is no such parameter.
"""
function neighbors(loop::Loop, at)
    lower = 0.0
    upper = 1.0
    for p in loop.poi
        t = poi.t
        if t > lower && t < at
            lower = t
        end
        if t > at && t < upper
            upper = t
        end
    end
    return lower, upper
end


abstract type Twist end
struct RightTwist <: Twist end
struct LeftTwist <: Twist end


"""
   reidemeister1(loop::Loop, at, twist::Twist)::Loop

Return a new loop by applying the Reidermeister I (twist) operation to
loop at `at`.  `twist`determines the direstion of twist.

"""
function reidemeister1(loop::Loop, at, twist)::Loop
    loop = grab(loop, at)
    before, after = neighbors(loop, at)
    # We need a parameter that is between `before` and `at`:
    t1 = (before + at ) / 2
    # and another between `at` and `after`:
    t2 = (at + after) / 2
    # These are the values of the parameter at which the loop will
    # cross itself to form the loop.

    # twist will determine whether the point of the loop at t1 will be
    # "below" (RightTwist) or "above" (LeftTwist) that at t2.


end

