
export KnotParameter, KP

"""
    KnotParameter(param::Float16)

KnotParameter is a floating point value modulo 1.  It represents the
parameter for a point on a parametric curve.

`KnotParameter`s can be added and subtracted.  They can be multiplied
by or divided by numbers.
"""
struct KnotParameter
    p::Rational

    KnotParameter(p) = new(mod(p, 1))
end

Base.zero(::KnotParameter) = KnotParameter(zero(Rational))
Base.zero(::Type{KnotParameter}) = KnotParameter(zero(Rational))

Base.typemin(::Type{KnotParameter}) = KnotParameter(0)
Base.typemax(::Type{KnotParameter}) = KnotParameter(999999//1000000)


Base.rem(kp1::KnotParameter, kp2::KnotParameter) =
    KnotParameter(rem(kp1.p, kp2.p))

Base.Float64(kp::KnotParameter) = Float64(kp.p)
Base.Float32(kp::KnotParameter) = Float32(kp.p)
Base.Float16(kp::KnotParameter) = Float16(kp.p)

KP = KnotParameter


Base.isless(a::KnotParameter, b::KnotParameter) = isless(a.p, b.p)

Base.:+(p1::KnotParameter, p2::KnotParameter)::KnotParameter =
    KnotParameter(p1.p + p2.p)

Base.:-(p1::KnotParameter, p2::KnotParameter)::KnotParameter =
    KnotParameter(p1.p - p2.p)    

Base.:/(p1::KnotParameter, d::Any)::KnotParameter =
    KnotParameter(p1.p / d)

convert(Number, p::KnotParameter) = p.p

Base.:*(a::Any, p::KnotParameter) = a * p.p
Base.:*(p::KnotParameter, a::Any) = p.p * a
Base.:/(n::Any, p::KnotParameter) = n / p.p
Base.:^(p::KnotParameter, e::Any) = p.p ^ e

Base.isless(p::KnotParameter, e::Any) = isless(p.p, e)
Base.isless(e::Any, p::KnotParameter) = isless(e, p.p)

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
