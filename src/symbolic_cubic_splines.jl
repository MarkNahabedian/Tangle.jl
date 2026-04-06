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
    symbolic_cubic_spline, vector_cubic_spline_segments,
    proximity_metric, metric_to_function, plot_metric,
    build_function_expression_value

islooped(poi::PointsOfInterest) =
    poi[1].p == typemin(KnotParameter) &&
    poi[end].p == typemax(KnotParameter) &&
    spatial_coordinates(poi[1]) == spatial_coordinates(poi[end])


build_function_expression_value(expression::Bool) =
    if expression
        Val{true}
    else
        Val{false}
    end


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


SYMBOLIC_CUBIC_SPLINES_FOLD = Val(true)


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
    looped = islooped(poi)
    [ symbolic_cubic_spline_segments_for_one_axis(:x, poi, looped),
      symbolic_cubic_spline_segments_for_one_axis(:y, poi, looped),
      symbolic_cubic_spline_segments_for_one_axis(:z, poi, looped)
      ]
end


function symbolic_cubic_spline_segments_for_one_axis(axis, poi::PointsOfInterest, looped::Bool)
    coefficient_vars = Num[]
    equations = Equation[]
    polynomials = []
    massage_kp(kp::KnotParameter) =
        if kp == typemax(KnotParameter)
            1//1
        else
            kp.p
        end
    @variables kp       # The KnotParameter
    # For N points we have one polynomial for each of the N-1
    # segments.  The end points of those segments are solutions to
    # that polynomial:
    for i in 1 : (length(poi) - 1)
        a = Symbolics.variable("a$i")
        b = Symbolics.variable("b$i")
        c = Symbolics.variable("c$i")
        d = Symbolics.variable("d$i")
        push!(coefficient_vars, a, b, c, d)
        polynomial = a * kp ^ 3 + b * kp ^ 2 + c * kp + d
        push!(polynomials, polynomial)
        # poi[i] is a solutiion to polynomial:
        push!(equations,
              getfield(poi[i], axis) ~ substitute(polynomial,
                                                  Dict(kp => massage_kp(poi[i].p));
                                                  fold = SYMBOLIC_CUBIC_SPLINES_FOLD))
        # So is poi[i+1]
        push!(equations,
              getfield(poi[i+1], axis) ~ substitute(polynomial,
                                                    Dict(kp => massage_kp(poi[i+1].p));
                                                    fold = SYMBOLIC_CUBIC_SPLINES_FOLD))
    end
    @assert length(polynomials) == length(poi) - 1
    ddkp(poly) = expand_derivatives(Differential(kp)(poly))
    function continuous_derivatives(p1, p2, point::PointOfInterest)
        subst = Dict(kp => massage_kp(point.p))
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
        continuous_derivatives(polynomials[i], polynomials[i+1], poi[i+1])
    end
    if looped
        # Treat the first and last points as a pair of
        # interior points since they form a loop:
        continuous_derivatives(polynomials[end], polynomials[1], poi[1])
        # continuous_derivatives(polynomials[end], polynomials[1], poi[end])
    else
        # The second derivatives of the first and last polynomials at the
        # end points are 0:
        push!(equations,
              0 ~ substitute(ddkp(ddkp(polynomials[1])),
                             Dict(kp => massage_kp(poi[1].p));
                             fold = SYMBOLIC_CUBIC_SPLINES_FOLD))
        push!(equations,
              0 ~ substitute(ddkp(ddkp(polynomials[end])),
                             Dict(kp => massage_kp(poi[end].p));
                             fold = SYMBOLIC_CUBIC_SPLINES_FOLD))
    end
    # Solve for the coefficients of the polymomials:
    global EQUATIONS = equations
    println("equations: ", equations)
    coefficients = OrderedDict(map(t -> Pair(t...),
                                   zip(coefficient_vars,
                                       symbolic_linear_solve(equations,
                                                             coefficient_vars))))
    # Substitute the coefficients into the polynomials:
    polynomials = map(polynomials) do p
        substitute(p, coefficients; fold = SYMBOLIC_CUBIC_SPLINES_FOLD)
    end
    function make_segment(i)
        SCSSegment(axis,
                   massage_kp(poi[i].p),
                   massage_kp(poi[i + 1].p),
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


function proximity_metric(knot_formula)
    kp = only(Symbolics.get_variables(knot_formula))
    @variables p1, p2
    kf1 = substitute(knot_formula, Dict(kp => p1))
    kf2 = substitute(knot_formula, Dict(kp => p2))
    # Should we skip doing the square root?
    sqrt(sum((kf1 - kf2) .^ 2)) / abs(p1 - p2)
end


function metric_to_function(metric)
    vars = sort(collect(Symbolics.get_variables(metric));
                by = x -> string(Symbolics.value(x)))
    build_function(metric, vars...; expression=build_function_expression_value(false))
end

function plot_metric(m; steps = 50)
    grid_range = 1 : 50
    grid = Array{Float64, 2}(undef, steps, steps)
    for i in grid_range
        for j in grid_range
            grid[i, j] = m(i // steps, j // steps)
        end
    end
    contourf(grid_range//steps, grid_range//steps, grid)
end


#=

More from Google Gemeni:

I'll be doing symbolic differentiation and possibly other math.  I
still have the expression that the function is compiled from though.

That’s the best way to handle it! Keeping the original Symbolics
expression around is much better than trying to work backward from the
compiled function.

Since you're doing symbolic differentiation, here are two quick tips
to keep in mind:

Differentiate First: Always perform your Symbolics.derivative or
Symbolics.jacobian on the symbolic expression before calling
build_function. Once it's compiled, you can't easily differentiate it
anymore.

Simplify: If your math gets complex, run simplify(expr) before
compiling. It can significantly speed up the resulting function by
removing redundant operations (like multiplying by 1 or adding 0).

julia
# Example workflow
D = Differential(x)
deriv_expr = expand_derivatives(D(your_expr))
simplified_deriv = simplify(deriv_expr)

# Now compile the optimized version
f_deriv = build_function(simplified_deriv, x, expression=build_function_expression_value(false))
Use code with caution.

Are you planning to calculate a Jacobian or Hessian for an
optimization problem or a solver?

My function is a parametric function whiich returns a point in 3
space.  The parameter ranges from 0 to 1.  The curve generated by the
function represents a knot.  I want to find "crossings" of that curve.
I could project it onto a place and try for an algebraic solution, or
attempt to minimize some distance metric of the function evaluated for
two different parameters.

That sounds like a classic self-intersection problem. Since it's a
knot, you’re looking for pairs

 where the curve 

 and 

are very close in a 2D projection, or truly intersecting if you were
looking for singularities (though for a knot, you usually want the
"near-misses" in 3D).

Using a distance metric is a robust way to handle this. You can define
a scalar objective function:

The "Avoid the Diagonal" Problem

If you just minimize this distance, the solver will immediately find
the global minimum

(where the distance is zero). To find actual crossings, you have a few
options:

Constraint: Add a constraint that 

to stay away from the trivial solution.

Modified Metric: Minimize

. This is related to the arc-length or ropelength energy; it penalizes
points that are close in space but far apart along the parameter of
the curve.

2D Projection: If you project to a plane (e.g., 
-plane), you are looking for roots of:


This is a system of two equations and two unknowns, which Symbolics.jl
is great at prepping for a Newton-Raphson solver.  Symbolic Workflow

Since you already have the expression, you can generate the Jacobian
of the 2D projection difference: julia

using Symbolics
@variables t1 t2
# P(t) is your 3D symbolic function
diff_vec = P(t1)[1:2] - P(t2)[1:2] # Projection to XY plane
jac = Symbolics.jacobian(diff_vec, [t1, t2])

# Build the functions for a root-finder
_, f! = build_function(diff_vec, [t1, t2], build_function_expression_value(false))
_, j! = build_function(jac, [t1, t2], build_function_expression_value(false))
Use code with caution.

Are you leaning toward the distance minimization (optimization) or the
projection (root-finding) approach?


For some knots, like the monkey fist, it would be difficult to find a
plane to project to, so I think the "distance metric" approach would
be more general, but perhaps more fraught.

You're right—for complex geometries like a monkey's fist, finding a
"good" projection plane that doesn't hide crossings or create messy
overlaps is a nightmare. The distance metric is definitely more
robust.  The "trivial minimum" (

) is the main hurdle. Since you are using Symbolics.jl, you can
actually bake the solution into your metric to make it easier for a
solver:

1. Use the "Chord-to-Arc" Ratio
Instead of minimizing raw distance 








, minimize the ratio of spatial distance to parameter distance:

Using the 
 term handles the periodic boundary of the knot (where 
 and 
 are the same point) and penalizes the solver for moving 
 and 
 too close together.
2. Analytical Gradient & Hessian
Since this is an optimization problem, providing the Hessian is a game-changer. For a 2-variable problem 




, the Hessian is just a 

 matrix. Symbolics can compute this instantly:
julia
# Assuming 'dist_metric' is your symbolic expression
grad = Symbolics.gradient(dist_metric, [t1, t2])
hess = Symbolics.hessian(dist_metric, [t1, t2])

# Build them all!
_, g! = build_function(grad, [t1, t2], build_function_expression_value(false))
_, h! = build_function(hess, [t1, t2], build_function_expression_value(false))
Use code with caution.

3. Multi-start or Grid Search
Because knots have many local minima (every near-miss is a potential minimum), a standard gradient descent will likely get stuck. You'll want to:
Generate a coarse grid of points 




 where 

.
Identify the "valleys" in the distance plot.
Use your compiled Symbolics functions to polish those candidates into high-precision coordinates.
Do you have the parameteric equations for the monkey's fist ready, or are you still constructing the symbolic expression for the curve?
Ready to create a plan?
Use Canvas to save, edit, and share your planning progress
Get started


My symbolics expressions are constructed by defining a cubic spline through an ordered set of points.  I'be not yet thought about how to construct a monkey fist.  So far I just have a single crossing -- an unknot with a single twist.
Using a cubic spline is a smart way to handle this because it ensures your curve is 
 continuous, which makes the Symbolic Gradient and Hessian much better behaved for your solver.
Since a Monkey's Fist is essentially a set of three orthogonal "wraps" around a core, you can eventually construct it by defining sets of points for the 


, and 
 windings and splining through them.
For your current "single crossing" unknot, here is a strategy to refine your search:
1. The "Off-Diagonal" Search
Since you are using a distance metric 





, the 2D parameter space is a 










 square. Because 











, you only need to search the lower triangle (

).
The diagonal (

) is your "enemy"—the distance there is zero.
The crossing you are looking for will be a local minimum in that triangle.
2. Handling the Spline Symbolically
If you are using Interpolations.jl or a manual cubic spline, ensure the piece-wise nature of the spline is handled. If the spline is defined over segments:
You can build a symbolic expression for each segment of the spline.
If your knot stays relatively simple, you can even use a Fourier Series or a single global Chebyshev polynomial to approximate the spline. This results in a single, smooth symbolic expression that is much easier for build_function to optimize than a massive piece-wise conditional.
3. Visualizing the Metric
Before you let a solver loose, I highly recommend evaluating your compiled distance function on a 2D grid:
julia
# Simple grid evaluation to see the "valleys"
t_range = 0:0.01:1
surface_data = [f_alloc([t1, t2]) for t1 in t_range, t2 in t_range]
Use code with caution.

In a knot, the crossings will appear as isolated pits away from the main diagonal "trench."
4. Pro-Tip: Arc-Length Parameterization
If your spline points are unevenly spaced, 
 might "speed up" or "slow down" along the curve. If you find the solver struggling, you might need to re-parameterize the spline by arc-length so that 

 is always exactly halfway along the string.
Are you using a standard library for the cubic spline, or did you write a custom symbolic matrix inversion to get the spline coefficients?





The ifelse predicates are mutually exclusive: t1 <= t < t2.
That is the cleanest way to structure it. Using t1 <= t < t2 ensures that Symbolics.jl treats the piecewise function as a single mathematical entity, and your generated code will behave like a standard branching Julia function.
Since your predicates are mutually exclusive, here are three technical details to keep in mind as you move toward finding crossings in more complex knots:
1. ifelse vs. if
When build_function compiles the code, it often preserves ifelse. In Julia, ifelse evaluates both branches before picking one. For a cubic spline, this is usually fine, but if your knot grows to 50+ segments, evaluating 50 cubic polynomials just to pick one is inefficient.
The Fix: If you notice performance lag, you can use Symbolics.to_expr and manually replace ifelse with standard if-else blocks, or use a SearchTree approach to find the segment index 
 for a given 
 before calling the polynomial.
2. Gradient "Glitches" at the Nodes
Even though a cubic spline is 
 continuous (meaning the value, slope, and curvature match at the boundaries), the symbolic derivative of an ifelse block can sometimes produce a NaN or a jump if the solver evaluates exactly at the boundary point 
.
Tip: If your solver (like Optim.jl) hits a boundary and stutters, slightly offsetting your predicates (e.g., 


) or using a "smooth" approximation (like a Sigmoid-based blend) can help, though usually, standard solvers handle 
 boundaries just fine.
3. The 2D Search Space
Since you are looking for 







, your distance metric 





 is a surface over the unit square.
The Monkey's Fist Challenge: In a complex knot, this surface will have many "trenches" (near-misses).
Because you've built the Hessian already, you can use a Newton-type method, which is incredibly fast once you are "near" a crossing.
How are you initializing your search? Are you picking random 




 pairs, or are you scanning a grid first to find the approximate locations of the crossings?



My polynomials are constructed such that the points and the first and second derivatives are equal at the boundaries.  I've not yet thought about how to do the search.
Since you’ve guaranteed 
 continuity (matching points, 1st, and 2nd derivatives), your Hessian will be continuous. This is the "gold standard" for optimization; it means a Newton-type solver will have a very smooth ride and converge quadratically once it's in the neighborhood of a crossing.
For the search strategy, here is a robust way to handle it without missing any "over-under" crossings:
1. The "Exclusion Zone"
You are searching for 




 in the unit square 










.
Ignore the diagonal: 

 is always a global minimum (distance = 0).
Symmetry: 











, so only search the lower triangle (

).
Local proximity: Points very close in parameter space (

) are just adjacent points on the string, not a crossing. You can ignore the "strip" where 




.
2. The Two-Step Search
For a complex knot like a Monkey's Fist, the distance surface will have many local minima. A single gradient descent will likely get "trapped" in the wrong one.
Coarse Grid Scan:
Evaluate your compiled f_alloc on a 2D grid (e.g., 

) over the lower triangle. Look for local minima in this grid—cells where the distance is smaller than all eight neighbors.
Newton Polishing:
For each local minimum found in the grid, use it as a starting point for a solver like Optim.jl or a manual Newton's method using your compiled Gradient and Hessian.
3. Newton's Method Update
Since you have the Hessian, the update step for your parameters 






 is:

This will "teleport" you to the bottom of the crossing "pit" in just a few iterations.
4. Detecting the Crossing Type
Once you find a minimum 




:
Physical Crossing: 





 will be very small (the "gap").
Over/Under: Check the 
-coordinates (or the coordinate omitted if projecting) to see which strand is "on top."
Would you like a snippet showing how to pass your compiled Symbolics functions into a solver like Optim.jl?



=#

