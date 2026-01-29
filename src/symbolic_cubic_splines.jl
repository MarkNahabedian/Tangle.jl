using Symbolics
using SymbolicUtils
using OrderedCollections
using LinearAlgebra

# Pkg.add("Groebner")
using Groebner              # for symbolics_solve

using Tangle

#=

If we have a symbolic representation for each knot formula we can
project the knot onto an arbitrary plane and look for parameters that
project to the same point.  This is how we can identify "crossings".

The plane we project to is identified by a unit vector N that is
normal to the plane.  If P is a point on the curve and PP is the point
it projects to, then PP = P - N * (N dot P.)

Is there a way that we can have both the Symbolics expression and a
knot function?  Calling the Loop could perform the substitution and
evaluation if necessary.

=#

SYMBOLIC_CUBIC_SPLINES_FOLD = true

function symbolic_cubic_spline(points, looped::Bool)
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
    println("\n*** equations:  ", equations)
    coefficients = OrderedDict(map(t -> Pair(t...),
                                   zip(coefficient_vars,
                                       symbolic_linear_solve(equations,
                                                             coefficient_vars))))
    println("\n*** coefficients:  ", coefficients)      # IT LOOKS LIKE WE'RE NOT SOLVING THE COEFFICIENTS.  They're all Nan.
    # Substitute the coefficients into the polynomials:
    polynomials = map(polynomials) do p
        # substitute doesn't work with OrderedDict:
        substitute(p, Dict(coefficients); fold = SYMBOLIC_CUBIC_SPLINES_FOLD)
    end
    function make_ifelse(i)
        if i == length(polynomials)
            polynomials[i]
        else
            Symbolics.ifelse(
                (massage_kp(points[i][1]) <= kp) &
                (kp < massage_kp(points[i + 1][1])),
                polynomials[i],
                make_ifelse(i + 1))
        end
    end
    make_ifelse(1)
end


#=
getvar(expr, v::Symbol) = first(filter(x -> x.name == v,
                                       collect(union(Set(),
                                                     map(Symbolics.get_variables, EQUATIONS)...))))
=#

getvar(expr, v::Symbol) = first(filter(x -> x.name == v,
                                       Symbolics.get_variables(expr)))

#=
getvar(exprs::Vector{Num}, v::Symbol) = first(filter(x -> x.name == v,
                                            union(Set(), map(Symbolics.get_variables, (exprs))...)))
=#



symbolic_cubic_spline(loop::Loop) = symbolic_cubic_spline(loop.poi)

function symbolic_cubic_spline(poi::PointsOfInterest)
    looped = poi[1].p == typemin(KnotParameter) &&
        poi[end].p == typemax(KnotParameter) &&
        spatial_coordinates(poi[1]) == spatial_coordinates(poi[end])
    Symbolics.Arr([ symbolic_cubic_spline(map(poi -> [poi.p, poi.x], poi), looped),   # x
                    symbolic_cubic_spline(map(poi -> [poi.p, poi.y], poi), looped),   # y
                    symbolic_cubic_spline(map(poi -> [poi.p, poi.z], poi), looped)    # z
                    ])
end


#=
function functionize(name::String, expr)
    kp = getvar(expr, :kp)
    f = Symbolics.variable("$name()")
=#


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


struct NoOp <: Operation
end

three_points =
    let
        op = NoOp()
        [
            PointOfInterest(KnotParameter(0//1), 0,  0,  0, :point1, op),
            PointOfInterest(KnotParameter(1//3), 2,  1,  0, :point2, op),
            PointOfInterest(KnotParameter(2//3), 2,  -1,  0, :point3, op),
            PointOfInterest(typemax(KnotParameter), 0, 0, 0, :closed, op)
        ]
    end

one_crossing =
    let
        op = NoOp()
        Loop([
            PointOfInterest(KnotParameter(0//8),     -2,  0,  0,   :left, op),
            PointOfInterest(KnotParameter(1//8),     -1,  1,  0,   :point2, op),
            PointOfInterest(KnotParameter(2//8),      0,  0,  1/2, :cross1a, op),
            PointOfInterest(KnotParameter(3//8),      1, -1,  0,   :point4, op),
            PointOfInterest(KnotParameter(4//8),      2,  0,  0,   :right, op),
            PointOfInterest(KnotParameter(5//8),      1,  1,  0,   :point6, op),
            PointOfInterest(KnotParameter(6//8),      0,  0, -1/2, :cross1b, op),
            PointOfInterest(KnotParameter(7//8),     -1, -1,  0,   :point8, op),
            PointOfInterest(typemax(KnotParameter), -2,  0,  0,   :end, op)
        ], op)
    end

# @variables one_crossing_function(x::KnotParameter)
one_crossing_function = symbolic_cubic_spline(one_crossing)

# @variables one_crossing_projection(x::KnotParameter)
one_crossing_projection = project([0, 0, 1], one_crossing_function)


# Can we make callable versions of one_crossing_function and
# one_crossing_projection that can still be manipulated symbolically?


# We want to find two different values of the parameter that map to
# the same point.  To do this we substitute new variables p1 and p2
# for p in one_crossing_projection, set the two resulting projections
# equal, and solve for p1 and p2.
function find_crossings(projection)
    #=
    println("find_crossings variables: ",
            sort(collect(union(Set(), map(Symbolics.get_variables, projection)));
                 by v -> v.name))
    =#
    @variables p1, p2
    kp = getvar(projection, :kp)
    # Solution generated with the assistance of Google Gemini (Google LLC, 2025).
    # Reference: https://gemini.google.com
    #
    # Google Gemeni says that from our cubic equation we can factor out
    # (p1 - p2).  The constant terms already cancel since they're the
    # same on both side of the equation.
    #
    # We can then use symbolic_solve.
    eq = [0, 0, 0] ~
        ((substitute(projection, Dict(kp => p1); fold = SYMBOLIC_CUBIC_SPLINES_FOLD) -
          substitute(projection, Dict(kp => p2); fold = SYMBOLIC_CUBIC_SPLINES_FOLD)) /
        (p1 - p2))
    println(eq)
    println(typeof(eq))
    symbolic_solve(eq, [p1, p2])
    # The above fails an assertion in check_expr_validity, which doesn't support ifelse.

    # Also, for multiple crossings we hope for multiple solutions.  Do
    # we need to try to solve an equation for the cross-product of the
    # loop segments?
end

# find_crossings(one_crossing_projection)


# What if insead we try to find crossings by computing the distance
# between the knot function points for two different values and then minimizing it.
# Minimize sum((knot(kp1) - knot(kp2)) .^2).




##### Debugging

equations = EQUATIONS

function list_equations(e = EQUATIONS)
    collect(enumerate(e))
end

function list_variables(e = EQUATIONS)
    sort(collect(union(Set(), map(Symbolics.get_variables, e)...));
         by = v -> v.name)
end

function few_unknowns(e = equations)
    filter(e -> 0 < length(Symbolics.get_variables(e[2])) <= 2,
           collect(enumerate(e)))
end


