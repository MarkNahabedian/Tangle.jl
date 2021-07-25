# Try a cartoon physics implementation instead

export Point, distance, direction
export Link, AlreadyLinked, fix_link_distance, chain
export previous_count, next_count, link_count


CoordType = Float32

struct Point <: StaticArrays.FieldVector{3, Number}
    x::CoordType
    y::CoordType
    z::CoordType
end

function distance(p1::Point, p2::Point)
    LinearAlgebra.norm(p2 - p1)
end

function direction(p1::Point, p2::Point)::Vec3
    unit_vector(p2 - p1)
end


@Base.kwdef mutable struct Link
    where::Point
    anchored::Bool = false
    next::Union{Nothing, Link} = nothing
    previous::Union{Nothing, Link} = nothing
    change::Vec3 = Vec3(0, 0, 0)
end

Link(x::Number, y::Number, z::Number) = Link(;where=Point(x, y, z))
Link(where::Point) = Link(;where=where)

Base.convert(::Type{Point}, link::Link) = link.where

function Base.iterate(link::Link)
    return link, link.next
end

function Base.iterate(::Link, state::Link)
    return state, state.next
end

Base.iterate(::Link, state::Nothing) = nothing

# The number of Links before link.  link itself is not counted.
# ????? Should we guard against circularity?
function previous_count(link::Link, count=0)::Integer
    if link.previous == nothing
        count
    else
        previous_count(link.previous, count + 1)
    end
end

# The number of Links after link.  link itself is not counted.
# ????? Should we guard against circularity?
function next_count(link::Link, count=0)::Integer
    if link.next == nothing
        count
    else
        next_count(link.next, count + 1)
    end
end

function link_count(link)::Integer
    previous_count(link) + 1 + next_count(link)
end

function start(link::Link)
    if link.previous == nothing
        link
    else
        start(link.previous)
    end
end

function finish(link::Link)
    if link.next == nothing
        link
    else
        finish(link.next)
    end
end

struct AlreadyLinked <: Exception
    link::Link
    direction

    function AlreadyLinked(link, direction)
        @assert direction in (:next, :previous)
        new(link, direction)
    end
end

function Base.showerror(io::IO, e::AlreadyLinked)
    print(io, "Link already has a $(e.direction)")
end

function connect(link1::Link, link2::Link)
    if link1.next != nothing
        throw(AlreadyLinked(link1, :next))
    end
    if link2.previous != nothing
        throw(AlreadyLinked(link2, :previous))
    end
    link1.next = link2
    link2.previous = link1
end

# ????? Do we need anything this complicated?
function direction(link::Link)::Vec3
    if link.next != nothing && link.previous != nothing
        return unit_vector(direction(link.previous, link) +
            direction(link, link.next))
    end
    if link.next != nothing
        return direction(link, link.next)
    end
    if link.previous != nothing
        return direction(link.previous, link)
    end
    return Vec3(0, 0, 0)
end


# curvature(::Link) based on cross product  with neighbors? Or average of direction if next and previous!



# a new Link is added when the distance between neighboring Links
# exceeds this
MAXIMUM_LINKED_DISTANCE = 1

# A Link is removed if it is closer to both of it's neighbors than
# this
MINIMUM_LINKED_DISTANCE = 0.2


# Two unrelated links are are moved away from each other if they are
# closer to each other than this
MINIMUM_UNLINKED_DISTANCE = 1

# a Link's next and previous links are moved apart from one another if
# the angle they form is less than this.  Each neighbor's distance
# from the subject link is preserved.
# MINIMUM_CURVATURE

# the largest change that will be performed in a single change step
MAXIMUM_CHANGE = 1



function fix_link_distance(link::Link)
    incr = MAXIMUM_LINKED_DISTANCE * unit_vector(link.next.where - link.where)
    this = link
    to = link.next
    this.next = nothing
    to.previous = nothing
    while true
        if distance(this.where, to.where) <= MAXIMUM_LINKED_DISTANCE
            connect(this, to)
            return
        end
        new_link = Link(Point(this.where + incr))
        connect(this, new_link)
        this = new_link
    end
end

# Return a bunch of linked Links, the first of which is at from and
# the last of which is at to
function chain(from::Link, to::Link)::Link
    if from.next != nothing
        throw(AlreadyLinked(from, :next))
    end
    if to.previous != nothing
        throw(AlreadyLinked(to, :previous))
    end
    connect(from, to)
    fix_link_distance(from)
    return from
end

# pull_to(::Link, new_posution, new_durection)
