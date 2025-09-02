
export KnotParameter, KP, MIN_KnotParameter, MAX_KnotParameter

"""
    KnotParameter(param::Float16)

KnotParameter is a floating point value modulo 1.  It represents the
parameter for a point on a parametric curve.

`KnotParameter`s can be added and subtracted.  They can be multiplied
by or divided by numbers.
"""
struct KnotParameter
    p::Float16

    KnotParameter(p) = new(mod(p, 1))
end

Base.zero(::KnotParameter) = KnotParameter(zero(Float16))
Base.zero(::Type{KnotParameter}) = KnotParameter(zero(Float16))

Base.rem(kp1::KnotParameter, kp2::KnotParameter) =
    KnotParameter(rem(kp1.p, kp2.p))

Base.Float64(kp::KnotParameter) = Float64(kp.p)
Base.Float32(kp::KnotParameter) = Float32(kp.p)
Base.Float16(kp::KnotParameter) = Float16(kp.p)

KP = KnotParameter

MIN_KnotParameter = KnotParameter(0)
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


"""
    divide_interval(from::KnotParameter, to::KnotParameter, count::Integer

Return `count` KnotParameters evenly spaced between `from` and `to`.
"""
function divide_interval(from::KnotParameter, to::KnotParameter,
                         count::Integer)::Vector{KnotParameter}
    delta = (to.p - from.p) / (count + 1)
    map(1:count) do i
        from + KnotParameter(i * delta)
    end
end
