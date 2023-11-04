using Symbolics
using Symbolics: variable


"""
    symbolic_vector(name::Symbol, n::Integer)

Define `n` Symbolics variables whose names are based on `name` and
return a vector of those variables.
"""
function symbolic_vector(name::Symbol, n::Integer)
    eltname(name, i) = Symbol("($name)_$i")
    map(variable, map(i -> eltname(name, i), 1:n))
end


"""
    vsubs(v::Vector{Symbolics.Num}, values...)

Return a list of `Pair`s suitable for constructing a `Dict` which is
suitable for passing to `Symbolics.substitute`, which
substitues each of `values` with the corresponding variable in `v`.
"""
function vsubs(v::Vector{Symbolics.Num}, values...)
	Pair.(v, values)
end


