# A KnotFunction implementation based on Symbolics.jl.

using Symbolics
using SymbolicUtils
using OrderedCollections
using LinearAlgebra

export SymbolicsKF


"""
    SymbolicsKF(loop::Loop)

Returns a Symbolics.jl based implementation of a [`KnotFunction`](@ref)
for the specified Loop.  The SymbolicsKF is cached in the `knot_functions`
field of Loop.
"""
struct SymbolicsKF <: KnotFunction
    expression
    func

    function SymbolicsKF(loop::Loop)
        kf = filter(kf -> kf isa SymbolicsKF, loop.knot_functions)
        if isempty(kf)
            expr = symbolic_cubic_spline(loop.poi)
            kp = only(Symbolics.get_variables(expr))
            func = build_function(expr, kp;
                                  expression=build_function_expression_value(false))[1]
            kf = new(expr, func)
            push!(loop.knot_functions, kf)
            return kf
        else
            return first(kf)
        end
    end
end

(kf::SymbolicsKF)(kp::Real) = Point(kf.func(kp)...)
(kf::SymbolicsKF)(kp::KnotParameter) = kf(kp.p)

