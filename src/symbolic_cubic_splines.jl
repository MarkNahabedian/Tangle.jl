using Symbolics
using SymbolicUtils
using OrderedCollections
using LinearAlgebra
# using NonLinearSolve

# Pkg.add("Groebner")
using Groebner              # for symbolics_solve
using Plots

using Tangle

export make_ifelse_for_segments, symbolic_cubic_spline_segments_for_axes,
    symbolic_cubic_spline

#=

If we have a symbolic representation for each knot formula we can
project the knot onto an arbitrary plane and look for parameters that
project to the same point.  This is how we can identify "crossings".

The plane we project to is identified by a unit vector N that is
normal to the plane.  If P is a point on the curve and PP is the point
it projects to, then PP = P - N * (N dot P)

Is there a way that we can have both the Symbolics expression and a
knot function?  Calling the Loop could perform the substitution and
evaluation if necessary.

=#

getvar(expr, v::Symbol) = first(filter(x -> x.name == v,
                                       Symbolics.get_variables(expr)))


SYMBOLIC_CUBIC_SPLINES_FOLD = true


struct SCSSegment
    axis
    lower_bound::Rational
    upper_bound::Rational
    polynomial
end

#=
symbolic_cubic_spline(ONE_CROSSING.loop.poi)
=#


symbolic_cubic_spline(poi::PointsOfInterest) =
    make_ifelse_for_segments(symbolic_cubic_spline_segments_for_axes(poi))


function make_ifelse_for_segments(segments)
    x_segments = segments[1]
    y_segments = segments[2]
    z_segments = segments[3]
    kp = getvar(x_segments[1].polynomial, :kp)
    function make_ifelse(i)
        arr = Symbolics.Arr([ x_segments[i].polynomial,
                              y_segments[i].polynomial,
                              z_segments[i].polynomial ])
        if i == length(x_segments)
            arr
        else
            Symbolics.ifelse(
                (x_segments[i].lower_bound <= kp) &
                    (kp < x_segments[i].upper_bound),
                arr,
                make_ifelse(i + 1))
        end
    end
    make_ifelse(1)
end

function symbolic_cubic_spline_segments_for_axes(poi::PointsOfInterest)
    looped = poi[1].p == typemin(KnotParameter) &&
        poi[end].p == typemax(KnotParameter) &&
        spatial_coordinates(poi[1]) == spatial_coordinates(poi[end])
    [ symbolic_cubic_spline_segments_for_one_axis(:x, map(poi -> [poi.p, poi.x], poi), looped),
      symbolic_cubic_spline_segments_for_one_axis(:y, map(poi -> [poi.p, poi.y], poi), looped),
      symbolic_cubic_spline_segments_for_one_axis(:z, map(poi -> [poi.p, poi.z], poi), looped)
      ]
end


function symbolic_cubic_spline_segments_for_one_axis(axis, points, looped::Bool)
    coefficient_vars = Num[]
    equations = []
    polynomials = []
    massage_kp(kp) =
        if kp == typemax(KnotParameter)
            1//1
        else
            kp.p
        end
    @variables kp       # The KnotParameter
    # For N points we have one polynomial for each of the N-1
    # segments.  The end points of those segments are solutions to
    # that polynomial:
    for i in 1 : (length(points) - 1)
        a = Symbolics.variable("a$i")
        b = Symbolics.variable("b$i")
        c = Symbolics.variable("c$i")
        d = Symbolics.variable("d$i")
        push!(coefficient_vars, a, b, c, d)
        polynomial = a * kp ^ 3 + b * kp ^ 2 + c * kp + d
        push!(polynomials, polynomial)
        # points[i] is a solutiion to polynomial:
        push!(equations,
              points[i][2] ~ substitute(polynomial,
                                        Dict(kp => massage_kp(points[i][1]));
                                        fold = SYMBOLIC_CUBIC_SPLINES_FOLD))
        # So is points[i+1]
        push!(equations,
              points[i+1][2] ~ substitute(polynomial,
                                          Dict(kp => massage_kp(points[i+1][1]));
                                          fold = SYMBOLIC_CUBIC_SPLINES_FOLD))
    end
    @assert length(polynomials) == length(points) - 1
    ddkp(poly) = expand_derivatives(Differential(kp)(poly))
    function continuous_derivatives(p1, p2, point)
        subst = Dict(kp => massage_kp(point[1]))
        # At any given interior point, the first derivatives of the two
        # polynomials adjacent to that point are equal at that point:
        push!(equations,
              substitute(ddkp(p1), subst) ~ substitute(ddkp(p2), subst;
                                                       fold = SYMBOLIC_CUBIC_SPLINES_FOLD))
        # At any given interior point, the second derivatives of
        # the two polynomials adjacent to that point are equal at
        # that point:
        push!(equations,
              substitute(ddkp(ddkp(p1)), subst) ~ substitute(ddkp(ddkp(p2)), subst;
                                                             fold = SYMBOLIC_CUBIC_SPLINES_FOLD))
    end
    for i in 1 : (length(polynomials) - 1)
        continuous_derivatives(polynomials[i], polynomials[i+1], points[i+1])
    end
    if looped
        # Treat the first and last points as a pair of
        # interior points since they form a loop:
        continuous_derivatives(polynomials[end], polynomials[1], points[1])
        # continuous_derivatives(polynomials[end], polynomials[1], points[end])
    else
        # The second derivatives of the first and last polynomials at the
        # end points are 0:
        push!(equations,
              0 ~ substitute(ddkp(ddkp(polynomials[1])),
                             Dict(kp => massage_kp(points[1][1]));
                             fold = SYMBOLIC_CUBIC_SPLINES_FOLD))
        push!(equations,
              0 ~ substitute(ddkp(ddkp(polynomials[end])),
                             Dict(kp => massage_kp(points[end][1]));
                             fold = SYMBOLIC_CUBIC_SPLINES_FOLD))
    end
    # Solve for the coefficients of the polymomials:
    global EQUATIONS = equations
    coefficients = OrderedDict(map(t -> Pair(t...),
                                   zip(coefficient_vars,
                                       symbolic_linear_solve(equations,
                                                             coefficient_vars))))
    # Substitute the coefficients into the polynomials:
    polynomials = map(polynomials) do p
        # substitute doesn't work with OrderedDict:
        substitute(p, Dict(coefficients); fold = SYMBOLIC_CUBIC_SPLINES_FOLD)
    end
    function make_segment(i)
        SCSSegment(axis,
                   massage_kp(points[i][1]),
                   massage_kp(points[i + 1][1]),
                   polynomials[i])
    end
    map(make_segment, 1 : length(polynomials))
end


"""
    project(plane, f)

Projects a parametric function `f` onto the plane identified by
`plane`, which should be a unit normal vector to the plane.

`f` is the result of calling `symbolic_cubic_spline` on a vector of
`PointOfInterest`s.
"""
function project(plane, f)
    @assert plane isa Vector
    @assert length(plane) == 3
    plane = plane ./ LinearAlgebra.norm(plane)
    f - plane .* sum(plane .* f)
end


##### Debugging

function list_equations(equations)
    collect(enumerate(equations))
end

function list_variables(equations)
    sort(collect(union(Set(), map(Symbolics.get_variables, equations)...));
         by = v -> v.name)
end

function few_unknowns(equations)
    filter(e -> 0 < length(Symbolics.get_variables(equations[2])) <= 2,
           collect(enumerate(equations)))
end


