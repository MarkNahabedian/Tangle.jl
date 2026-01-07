using Symbolics
using SymbolicUtils
using OrderedCollections

#=

If we have a symbolic representation for each knot formula we can
project the knot onto an arbitrary plane and look for parameters that
project to the same point.  This is how we can identify "crossings".

The plane we project to is identified by a unit vector N that is
normal to the plane.  If P is a point on the line and PP is the point
it projects to, then Pp = P - N dot P.

Is there a way that we can have both the Symbolics expression and a
knot function?  Calling the Loop could perform the substitution and
evaluation if necessary.

=#

function symbolic_cubic_spline(points)
    coefficients = []
    equations = []
    polynomials = []
    @variables x
    # For N points we have one polynomial for each of the N-1
    # segments.  The end points of those segments are solutions to
    # that polynomial:
    for i in 1 : (length(points) - 1)
        a = Symbolics.variable("a$i")
        b = Symbolics.variable("b$i")
        c = Symbolics.variable("c$i")
        d = Symbolics.variable("d$i")
        push!(coefficients, a, b, c, d)
        polynomial = a * x ^ 3 + b * x ^ 2 + c * x + d
        push!(polynomials, polynomial)
        # points[i] is a solutiion to polynomial:
        push!(equations,
              points[i][2] ~ substitute(polynomial,
                                        Dict(x => points[i][1])))
        # So is points[i+1]
        push!(equations,
              points[i+1][2] ~ substitute(polynomial,
                                          Dict(x => points[i+1][1])))
    end
    ddx(poly) = expand_derivatives(Differential(x)(poly))
    for i in 1 : (length(polynomials) - 1)
        let
            point = points[i+1]
            p1 = polynomials[i]
            p2 = polynomials[i+1]
            subst = Dict(x => point[1])
            # At any given interior point, the first derivatives of the two
            # polynomials adjacent to that point are equal at that point:
            push!(equations,
                  substitute(ddx(p1), subst) ~ substitute(ddx(p2), subst))
            # At any given interior point, the second derivatives of
            # the two polynomials adjacent to that point are equal at
            # that point:
            push!(equations,
                  substitute(ddx(ddx(p1)), subst) ~ substitute(ddx(ddx(p2)), subst))
        end
    end
    # The second derivatives of the first and last polynomials at the
    # end points are 0:
    push!(equations,
          0 ~ substitute(ddx(ddx(polynomials[1])), Dict(x => points[1][1])))
    push!(equations,
          0 ~ substitute(ddx(ddx(polynomials[end])), Dict(x => points[end][1])))
    println("equations:\n\t", equations)
    # Solve for the coefficients of the polymomials:
    coefficients = OrderedDict(zip(coefficients, solve_for(equations, coefficients)))
    println("coefficients:\n\t", coefficients)
    # Substitute the coefficients into the polynomials:
    polynomials = map(polynomials) do p
        substitute(p, coefficients)
    end
    function make_ifelse(points, polynomials)
        if isempty(points)
            nothing
        else
            ifelse(x < points[1][1],
                   first(polynomials),
                   make_ifelse(points[2:end], polynomials[2:end]))
        end
    end
    make_ifelse(points, [nothing, polynomials...])
end


#=
begin
    points = [[0, 0], [1, 1], [2, 0], [2, 2]]
    i = 1
    a = Symbolics.variable("a$i")
    b = Symbolics.variable("b$i")
    c = Symbolics.variable("c$i")
    d = Symbolics.variable("d$i")
    polynomial = a * x ^ 3 + b * x ^ 2 + c * x + d
    println(polynomial)
    @variables x
    println(substitute(polynomial, Dict(x => points[i][1])))
end
=#

