
export PointOfInterest, PointsOfInterest, coordinates, spatial_coordinates


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
    x::Real
    y::Real
    z::Real
    label
    operation::Operation
    is_crosspoint::Bool = false
end

PointOfInterest(p::KnotParameter,
                x::Real, y::Real, z::Real,
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

spatial_coordinates(poi::PointsOfInterest) =
    map(spatial_coordinates, poi)

function spatial_coordinates(point::Vector)
    # ??? Should we verify the element types?
    if length(point) == 3
        return point
    else
        return point[2:end]
    end
end

# Integration with CoordinateTransformations (indexing of coordinates):

Base.length(p::PointOfInterest) = 3
Base.size(p::PointOfInterest) = (3,)

function Base.getindex(p::PointOfInterest, index::Int)
    if index == 1
        return p.x
    elseif index == 2
        return p.y
    elseif index == 3
        return p.z
    else
        throw(BoundsError(p, index))
    end
end

# We might find we need more methods for subtypes of Transformation.

(t::LinearMap)(poi::PointOfInterest) =
    PointOfInterest(poi.p,
                    t(spatial_coordinates(poi))...,
                    poi.label,
                    poi.operation,
                    poi.is_crosspoint)

(t::Translation)(poi::PointOfInterest) =
    PointOfInterest(poi.p,
                    t(spatial_coordinates(poi))...,
                    poi.label,
                    poi.operation,
                    poi.is_crosspoint)

#=
const Segment = Tuple{PointOfInterest,PointOfInterest}

distance(s::Segment) = distance(vector(s))

vector(s::Segment) = s[2] - s[1]

=#

