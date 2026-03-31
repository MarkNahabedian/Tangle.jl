# This code works in Symbolics 6 but gets an error in Symbolics 7.  I
# think I'm using `substitute` correctly.

using Pkg
Pkg.activate(; temp=true)
Pkg.add("GeometryBasics")
Pkg.add("LinearAlgebra")
Pkg.add(;name="Symbolics", version="7")
using GeometryBasics
using Symbolics
using LinearAlgebra

POINTS = [
    [0//8,     -2,  0,  0],
    [1//8,     -1,  1,  0],
    [2//8,      0,  0,  1/2],
    [3//8,      1, -1,  0],
    [4//8,      2,  0,  0],
    [5//8,      1,  1,  0],
    [6//8,      0,  0, -1/2],
    [7//8,     -1, -1,  0],
]

let
    axis = :x
    coefficient_vars = Num[]
    equations = []
    polynomials = []
    @variables kp
    i = 1
    a = Symbolics.variable("a$i")
    b = Symbolics.variable("b$i")
    c = Symbolics.variable("c$i")
    d = Symbolics.variable("d$i")
    push!(coefficient_vars, a, b, c, d)
    polynomial = a * kp ^ 3 + b * kp ^ 2 + c * kp + d
    push!(polynomials, polynomial)
    p, x, y, z = POINTS[i]
    push!(equations,
          # I think Im using substitute correctly here:
          POINTS[i][2] ~ substitute(polynomial,
                                    Dict(kp => p);
                                    fold = true))
    equations
end
