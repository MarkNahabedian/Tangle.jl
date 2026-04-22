# An implementation of KnotFunction based on CubicSpline

using CubicSplines

export CSKF


"""
    CSKF(loop::Loop)

Returns a CubicSpline based implementation of a [`KnotFunction`](@ref)
for the specified Loop.  The CSRF is cached in the `knot_functions`
field of Loop.
"""
struct CSKF <: KnotFunction
    x
    y
    z

    function CSKF(loop::Loop)
        values(fieldname) = map(p -> getfield(p, fieldname), loop.poi)
        p = map(kp -> Float64(kp.p), values(:p))
        kf = filter(kf -> kf isa CSKF, loop.knot_functions)
        if isempty(kf)
            kf = new(CubicSpline(p, values(:x)),
                     CubicSpline(p, values(:y)),
                     CubicSpline(p, values(:z)))
            push!(loop.knot_functions, kf)
            return kf
        else
            return first(kf)
        end
    end
end

(cskf::CSKF)(kp::Real) = Point(cskf.x(kp), cskf.y(kp), cskf.z(kp))
(cskf::CSKF)(kp::KnotParameter) = cskf(kp.p)

