
struct KnotParameter
    p::Float16

    KnotParameter(p) = new(mod(p, 1))
end

KP = KnotParameter

Base.:+(p1::KnotParameter, p2::KnotParameter)::KnotParameter =
    KnotParameter(p1.p + p2.p)

Base.:-(p1::KnotParameter, p2::KnotParameter)::KnotParameter =
    KnotParameter(p1.p - p2.p)    

Base.:/(p1::KnotParameter, d::Real)::KnotParameter =
    KnotParameter(p1.p / d)

