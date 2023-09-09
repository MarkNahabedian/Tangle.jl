
export KnotParameter, KP, MAX_KnotParameter

struct KnotParameter
    p::Float16

    KnotParameter(p) = new(mod(p, 1))
end

KP = KnotParameter

MAX_KnotParameter = KnotParameter(prevfloat(Float16(1.0)))

Base.isless(a::KnotParameter, b::KnotParameter) = isless(a.p, b.p)

Base.:+(p1::KnotParameter, p2::KnotParameter)::KnotParameter =
    KnotParameter(p1.p + p2.p)

Base.:-(p1::KnotParameter, p2::KnotParameter)::KnotParameter =
    KnotParameter(p1.p - p2.p)    

Base.:/(p1::KnotParameter, d::Real)::KnotParameter =
    KnotParameter(p1.p / d)

convert(Number, p::KnotParameter) = p.p

Base.:*(a::Number, p::KnotParameter) = a * p.p
Base.:*(p::KnotParameter, a::Number) = p.p * a
Base.:/(n::Float64, p::KnotParameter) = n / p.p

