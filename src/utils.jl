
distance(v) = sqrt(reduce(+, (map(n -> n^2, v))))

function unit_vector(v)
    v / distance(v)
end

function cross(a, b)
    [
    a[2] * b[3] − a[3] * b[2],
    a[3] * b[1] − a[1] * b[3],
    a[1] * b[2] − a[2] * b[1]
    ]
end

