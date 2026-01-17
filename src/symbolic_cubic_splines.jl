using Symbolics
using SymbolicUtils
using OrderedCollections
using LinearAlgebra

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

function symbolic_cubic_spline(points, looped::Bool)
    coefficients = []
    equations = []
    polynomials = []
    @variables kp       # The KnotParameter
    # For N points we have one polynomial for each of the N-1
    # segments.  The end points of those segments are solutions to
    # that polynomial:
    for i in 1 : (length(points) - 1)
        a = Symbolics.variable("a$i")
        b = Symbolics.variable("b$i")
        c = Symbolics.variable("c$i")
        d = Symbolics.variable("d$i")
        push!(coefficients, a, b, c, d)
        polynomial = a * kp ^ 3 + b * kp ^ 2 + c * kp + d
        push!(polynomials, polynomial)
        # points[i] is a solutiion to polynomial:
        push!(equations,
              points[i][2] ~ substitute(polynomial,
                                        Dict(kp => points[i][1].p)))
        # So is points[i+1]
        push!(equations,
              points[i+1][2] ~ substitute(polynomial,
                                          Dict(kp => points[i+1][1].p)))
    end
    @assert length(polynomials) == length(points) - 1
    ddkp(poly) = expand_derivatives(Differential(kp)(poly))
    function continuous_derivatives(p1, p2, point)
        subst = Dict(kp => point[1].p)
        # At any given interior point, the first derivatives of the two
        # polynomials adjacent to that point are equal at that point:
        push!(equations,
              substitute(ddkp(p1), subst) ~ substitute(ddkp(p2), subst))
        # At any given interior point, the second derivatives of
        # the two polynomials adjacent to that point are equal at
        # that point:
        push!(equations,
              substitute(ddkp(ddkp(p1)), subst) ~ substitute(ddkp(ddkp(p2)), subst))
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
              0 ~ substitute(ddkp(ddkp(polynomials[1])), Dict(kp => points[1][1].p)))
        push!(equations,
              0 ~ substitute(ddkp(ddkp(polynomials[end])), Dict(kp => points[end][1].p)))
    end
    # Solve for the coefficients of the polymomials:
    global EQUATIONS = equations
    println("\n*** equations:  ", equations)
    coefficients = OrderedDict(zip(coefficients,
                                   symbolic_linear_solve(equations, coefficients)))
    println("\n*** coefficients:  ", coefficients)      # IT LOOKS LIKE WE'RE NOT SOLVING THE COEFFICIENTS.  They're all Nan.
    # Substitute the coefficients into the polynomials:
    polynomials = map(polynomials) do p
        substitute(p, coefficients)
    end
    function make_ifelse(i)
        if i == length(polynomials)
            polynomials[i]
        else
            Symbolics.ifelse((points[i][1] <= kp) & (kp < points[i + 1][1]),
                             polynomials[i],
                             make_ifelse(i + 1))
        end
    end
    make_ifelse(1)
end

### WHY ARE ALL OF THE COEFFICIENTS AVOVE NaNs?


symbolic_cubic_spline(loop::Loop) = symbolic_cubic_spline(loop.poi)

function symbolic_cubic_spline(poi::PointsOfInterest)
    looped = poi[1].p == typemin(KnotParameter) &&
        poi[end].p == typemax(KnotParameter) &&
        spatial_coordinates(poi[1]) == spatial_coordinates(poi[end])
    [ symbolic_cubic_spline(map(poi -> [poi.p, poi.x], poi), looped),   # x
      symbolic_cubic_spline(map(poi -> [poi.p, poi.y], poi), looped),   # y
      symbolic_cubic_spline(map(poi -> [poi.p, poi.z], poi), looped)    # z
    ]
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

struct NoOp <: Operation
end

three_points =
    let
        op = NoOp()
        [
            PointOfInterest(KnotParameter(0.0), 0,  0,  0, :point1, op),
            PointOfInterest(KnotParameter(0.3), 2,  1,  0, :point2, op),
            PointOfInterest(KnotParameter(0.7), 2,  -1,  0, :point3, op),
        ]
    end


one_crossing =
    let
        op = NoOp()
        Loop([
            PointOfInterest(KnotParameter(0.0),     -2,  0,  0,   :left, op),
            PointOfInterest(KnotParameter(0.1),     -1,  1,  0,   :point2, op),
            PointOfInterest(KnotParameter(0.2),      0,  0,  0.5, :cross1a, op),
            PointOfInterest(KnotParameter(0.3),      1, -1,  0,   :point4, op),
            PointOfInterest(KnotParameter(0.4),      2,  0,  0,   :right, op),
            PointOfInterest(KnotParameter(0.5),      1,  1,  0,   :point6, op),
            PointOfInterest(KnotParameter(0.6),      0,  0, -0.5, :cross1b, op),
            PointOfInterest(KnotParameter(0.7),     -1, -1,  0,   :point8, op),
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
#=
function find_crossings(projection)
    sort(collect(union(Set(), map(Symbolics.get_variables, projection))))
    @variables p1, p2
    substitute(projection, Dict(getvar(:p) => p1)) ~
        substitute(projection, Dict(getvar(:p) => p2))
end
=#


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

getvar(expr, v::Symbol) = first(filter(x -> x.name == v,
                                       collect(union(Set(),
                                                     map(Symbolics.get_variables, EQUATIONS)...))))



#=   NEW SOLUTION ATTEMPT:

few_unknowns()
1-element Vector{Tuple{Int64, Any}}:
 (1, 0 ~ c1*KnotParameter(Float16(0.0)) + d1)

###   d1 ~ 0.0
equations = map(equations) do e
    substitute(e, Dict(getvar(e, :d1) => 0.0))
end

# few_unknowns()  now has no meaningful results





=#

#=     OLD SOLUTION ATTEMPT:

#  (31, 0 ~ 6a1*KnotParameter(Float16(0.0)) + 2b1)
equations = map(equations) do e
    substitute(e, Dict(getvar(:b1) => (getvar(:a1) * -6 * KnotParameter(Float16(0.0))) / 2))
end

#   (32, 0 ~ 6a8*KnotParameter(Float16(0.7)) + 2b8)
equations = map(equations) do e
    substitute(e, Dict(getvar(:b8) => -2.102))
end

filter(e -> length(Symbolics.get_variables(e[2])) <= 2, collect(enumerate(equations)))


=#

#=

X:

symbolic_cubic_spline(map(poi -> [poi.p, poi.x], one_crossing.poi), false)

equations = EQUATIONS

collect(enumerate(equations))

VARIABLES = sort(collect(union(Set(), map(Symbolics.get_variables, EQUATIONS)...));
                 by = v -> v.name)

### 27
filter(e -> length(Symbolics.get_variables(e[2])) <= 2, collect(enumerate(equations)))

solve_for(equations[27], [getvar(equations[27], :b1)])
1-element Vector{Float16}:
 -0.0

equations = map(equations) do e
    substitute(e, Dict(getvar(e, :b1) => 0.0))
end

### 1
solve_for(equations[1], [getvar(equations[1], :d1)])
1-element Vector{Float16}:
 -2.0

equations = map(equations) do e
    substitute(e, Dict(getvar(e, :d1) => -2.0))
end

### 28
solve_for(equations[28], [getvar(equations[28], :b7)])
1-element Vector{SymbolicUtils.BasicSymbolic{Real}}:
 -2.102a7

equations = map(equations) do e
    substitute(e, Dict(getvar(e, :b7) =>  -2.102 * getvar(e, :a7)))
end

solve_for(equations[28], [getvar(equations[28], :a7)])
equations = map(equations) do e
    substitute(e, Dict(getvar(e, :a7) => 0.0))
end

###
 (13, 0 ~ c7*KnotParameter(Float16(0.6)) + d7)
 (14, -1 ~ c7*KnotParameter(Float16(0.7)) + d7)

solve_for(equations[13], [getvar(equations[13], :d7)])
1-element Vector{SymbolicUtils.BasicSymbolic{Real}}:
 -0.6c7

julia> solve_for(equations[14], [getvar(equations[14], :d7)])
solve_for(equations[14], [getvar(equations[14], :d7)])
1-element Vector{SymbolicUtils.BasicSymbolic{Real}}:
 -1 - 0.7c7

-0.6c7 ~  -1 - 0.7c7
0.6c7 ~  1 + 0.7c7
-1 = 0.1c7
c7 ~ -10

equations = map(equations) do e
    substitute(e, Dict(getvar(e, :c7) => -10.0))
end

###
filter(e -> length(Symbolics.get_variables(e[2])) <= 2, collect(enumerate(equations)))
 (1, -2 ~ -2.0 + c1*KnotParameter(Float16(0.0)))
 (2, -1 ~ -2.0 + 0.000999a1 + c1*KnotParameter(Float16(0.1)))
 (13, 0 ~ -6.0009765625 + d7)
 (14, -1 ~ -7.001953125 + d7)
 (26, 6a6*KnotParameter(Float16(0.6)) + 2b6 ~ 0.0)
 (27, 0 ~ 6a1*KnotParameter(Float16(0.0)))
 (28, 0 ~ 0.0)

solve_for(equations[13], [getvar(equations[13], :d7)])
1-element Vector{Float64}:
 6.0009765625

solve_for(equations[14], [getvar(equations[14], :d7)])
1-element Vector{Float64}:
 6.001953125

### 2
solve_for(equations[2], [getvar(equations[2], :a1)])
1-element Vector{SymbolicUtils.BasicSymbolic{Real}}:
 1.0005e3(1.0 - 0.1c1)

equations = map(equations) do e
    substitute(e, Dict(getvar(e, :a1) => 1.0005e3 * (1.0 - 0.1 * getvar(e, :c1))))
end

### 2
solve_for(equations[2], [getvar(equations[2], :c1)])
1-element Vector{Float64}:
 -2.5490196078420464

equations = map(equations) do e
    substitute(e, Dict(getvar(e, :c1) => -2.5490196078420464))
end

### 16
solve_for(equations[16], [getvar(equations[16], :b2)])
1-element Vector{SymbolicUtils.BasicSymbolic{Real}}:
 0.5(753.1337316175816 - 0.5996a2)

equations = map(equations) do e
    substitute(e, Dict(getvar(e, :b2) => 0.5(753.1337316175816 - 0.5996 * getvar(e, :a2))))
end

### 26
solve_for(equations[26], [getvar(equations[26], :b6)])
1-element Vector{SymbolicUtils.BasicSymbolic{Real}}:
 -1.801a6

equations = map(equations) do e
    substitute(e, Dict(getvar(e, :b6) =>  -1.801 * getvar(e, :a6)))
end

### 25
solve_for(equations[25], [getvar(equations[25], :a6)])
1-element Vector{SymbolicUtils.BasicSymbolic{Real}}:
 0.9246642448409784(10.0 + c6)

equations = map(equations) do e
    substitute(e, Dict(getvar(e, :a6) => 0.9246642448409784 * (10.0 + getvar(e, :c6))))
end

### 11, 12, d6
solve_for(equations[11], [getvar(equations[11], :d6)])
1-element Vector{SymbolicUtils.BasicSymbolic{Real}}:
 1 + 0.3007470456345282(10.0 + c6) - 0.5c6

solve_for(equations[12], [getvar(equations[12], :d6)])
1-element Vector{SymbolicUtils.BasicSymbolic{Real}}:
 0.39990712722892385(10.0 + c6) - 0.6c6

equations = map(equations) do e
    substitute(e, Dict(getvar(e, :d6) =>  0.39990712722892385(10.0 + getvar(e, :c6)) - 0.6 * getvar(e, :c6)))
end


WHAT ABOUT THE PROBLEM WITH d7

 (13, 0 ~ 0.2161a7 + 0.36b7 + c7*KnotParameter(Float16(0.6)) + d7)
 (14, -1 ~ 0.3433a7 + 0.4902b7 + c7*KnotParameter(Float16(0.7)) + d7)

symbolic_linear_solve(EQUATIONS[13], [getvar(EQUATIONS[13], :d7)])
d7 ~  -0.2161a7 - 0.36b7 - 0.6c7

symbolic_linear_solve(EQUATIONS[14], [getvar(EQUATIONS[14], :d7)])
d7 ~  -1 - 0.3433a7 - 0.4902b7 - 0.7c7

substitute(e, Dict(getvar(e, :a7) => 0.0))
ubstitute(e, Dict(getvar(e, :b7) =>  -2.102 * getvar(e, :a7)))




sort(collect(union(Set(), map(Symbolics.get_variables, equations)...));
                 by = v -> v.name)

=#
