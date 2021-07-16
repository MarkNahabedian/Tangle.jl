
export Vec3, unit_vector, distance

struct Vec3 <: StaticArrays.FieldVector{3, Number}
    x::Number
    y::Number
    z::Number
end

function unit_vector(vector)
    vector / LinearAlgebra.norm(vector)
end

function distance(v1, v2)::Number
    LinearAlgebra.norm(v2 - v1)
end
