
export Operation, PointOfInterest, coordinates, spatial_coordinates


abstract type Operation
# Every Operation should have a field named "sequence" that is
# unique within a given Loop.
# Should every operation (except for InitializeLoop) have a previous Loop?
end


"""
    PointOfInterest

PointOfInterest represents a point on a `Loop` for which a location
has been specified.

No two points of interest should have the same KnotParameter widthin a
Loop.

No two points of interest should have equal coordinates within the
same mathematical link.

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


"""
PointsOfInterest is a sequence whose elements are PointsOfInterest
objects.
"""
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

#=
const Segment = Tuple{PointOfInterest,PointOfInterest}

distance(s::Segment) = distance(vector(s))

vector(s::Segment) = s[2] - s[1]

=#
