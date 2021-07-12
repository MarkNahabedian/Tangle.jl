export DEFAULT_CROSSING_GAP, DEFAULT_LOOP_DIAMETER
export StrandPoint, center, Bounds, bounds, Strand, maxThickness,
    Bounds, addPoint, nearest, pointAt

"""
The default value for the gap parameter to some functions.  The gap
parameter is multiplied by strand thickness to get the center to
center spacing of two strands when they cross.
"""
DEFAULT_CROSSING_GAP = 2

"""
The default value for the loop diameter for functions that make a
loop.  This factor is multipled by the strand thickness to compute the
diameter of the loop.
"""
DEFAULT_LOOP_DIAMETER = 10

"""
`StrandPoint` provides a way to anchor part of a `Strand` at some
point in 3 space.  `p` should monotonically increase along the length
of the Strand.
"""
struct StrandPoint
    p::Real
    x::Real
    y::Real
    z::Real
end

function center(points)::StrandPoint
    count, p, x, y, z = 0, 0, 0, 0, 0
    for point in points
        count += 1
        p += point.p
        x += point.x
        y += point.y
        z += point.z
    end
    return StrandPoint(p/count, x/count, y/count, z/count)
end

struct StrandPointOrdering <: Base.Order.Ordering
end

Base.Order.lt(o::StrandPointOrdering, a, b) = a.p < b.p

struct Bounds
    minP
    maxP
    minX
    maxX
    minY
    maxY
    minZ
    maxZ
end

"""
`Strand` models a single strand of fiber (rope, yarn or whatever).
A Strand is infinite in length.
"""
@Base.kwdef struct Strand
    # For convenience in identifying them, a Strand can have a label:
    label = nothing
    # The thickness of a strand affects how they are drawn and how
    # close they can be to other Strands:
    thickness = 0.1
    # These points constrain the path of the STrand:
    points::SortedSet{StrandPoint, StrandPointOrdering} =
        SortedSet{StrandPoint}(StrandPointOrdering())
end

function maxThickness(strands...)
    maximum([strand.thickness for strand in strands])
end

# How can we enforce that a Strand doesn't cross itself or any other
# strand except at a known pair of StrandPoints?  What does this mean?
# Does it mean that no two StrandPoints across all strands are within
# strand.thickness of each other?

# Should we reify an object that represents an explicityly made
# crossing to distinguish them from "accidental" ones or can we trust
# that the accidental ones wont have explicit points?

# Should we enforce that segments of strands don't cross each other.

"""
addPoint sets a waypoint for the strand.  The StrandPoint is
returned.
"""
function addPoint end

function addPoint(strand::Strand, point::StrandPoint)
    # Should we order strand.points by p?
    for existing in strand.points
        if point.p == existing.p
            throw(Exception("StandPoint with parameter $(point.p) already present in $strand."))
        end
    end
    insert!(strand.points, point)
    return point
end

function addPoint(strand, p, x, y, z)
    addPoint(strand, StrandPoint(p, x, y, z))
end

"""
    nearest(strand, p)
Return the closest `StrandPoint`s of `strand` before and after
parameter `p`.  If `strand` has no points then `nothing, nothing` is
returned.  Note that if `strand` has a `StrandPoint` at `p` then both
return values will be the same.
Any `StrandPoint` with parameter `p` is excluded from consideration.
"""
function nearest(strand::Strand, p::Real)
    # searchsortedfirst, searchsortedafter
    if length(strand.points) == 0
        return nothing, nothing
    end
    before = nothing
    after = nothing
    # Since strand.points is a SortedSet, there might be a more
    # optimal way to do this.
    for point in strand.points
        if point.p < p
            if before == nothing || point.p > before.p
                before = point
            end
        elseif point.p > p
            if after == nothing || point.p < after.p
                after = point
            end
        end
    end
    return before, after
end

function pointAt(strand, p)::Union{Nothing, StrandPoint}
    p1, p2 = nearest(strand, p)
    if p1 == p2
        return p1
    end
    # *** What if either p1 or p2 are nothing?
    if p1 == nothing || p2 == nothing
        return nothing
    end
    # center is wrong.  We need to linearly interpolate.
    factor = (p - p1.p) / (p2.p - p1.p)
    p3 = StrandPoint(p,
                     p1.x + factor * (p2.x - p1.x),
                     p1.y + factor * (p2.y - p1.y),
                     p1.z + factor * (p2.z - p1.z))
    # Add p3 to strand to ensure repeatability
    addPoint(strand, p3)
    return p3
end

function bounds(strand::Strand)
    if length(strand.points) == 0
        return nothing
    end
    point1 = first(strand.points)
    minP = point1.p
    maxP = point1.p
    minX = point1.x
    maxX = point1.x
    minY = point1.y
    maxY = point1.y
    minZ = point1.z
    maxZ = point1.z
    for point in strand.points
        minP = min(minP, point.p)
        maxP = max(maxP, point.p)
        minX = min(minX, point.x)
        maxX = max(maxX, point.x)
        minY = min(minY, point.y)
        maxY = max(maxY, point.y)
        minZ = min(minZ, point.z)
        maxZ = max(maxZ, point.z)
    end
    return Bounds(minP, maxP, minX, maxX, minY, maxY, minZ, maxZ)
end

# Most fabrics are relatively flat.  For these we can assume that all
# Strands are within some small margin of the z=0 plane.

function cross(over::Strand, overP, under::Strand, underP, x, y;
               gap=DEFAULT_CROSSING_GAP)::Tuple{StrandPoint, StrandPoint}
    thickness = maxThickness(over, under)
    point1 = StrandPoint(overP, x, y, gap * thickness)
    addPoint(over, point1)
    point2 = StrandPoint(underP, x, y, - gap * thickness)
    addPoint(under, point2)
    return point1, point2
end
