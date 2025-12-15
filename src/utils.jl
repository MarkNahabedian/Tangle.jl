export distance, unit_vector

distance(v) = sqrt(sum(n -> n^2, v))

#=
function cross(a, b)
    [
    a[2] * b[3] − a[3] * b[2],
    a[3] * b[1] − a[1] * b[3],
    a[1] * b[2] − a[2] * b[1]
    ]
end
=#
