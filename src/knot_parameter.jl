
export KnotParameter, divide_interval

#=

KnotParameter is the type used as the parameter of a knot function.
Since a knot function defines a loop, the domain of a knot function
should identify points on a circular path.

Avoid floating point numbers because they are not exact.  A previous
attempt to use subtypes of Unsigned also lead to inexact arithmetic
when, for example, attempting to divide a KnotParameter by 3.

WWhat do we want from arithmetic on knot parameters:

* typemin, typemax, zero

* isless, for sorting

* exact arithmetic.

* modular addition and subtraction.

* modular multiplication by an exact numeric.

* modular division of the space between two knot parameters into a
specified number of even intervals.

* convert of a KnotParameter to a fraction in the interval 0 <= kp < 1.

For generating the symbolic parametric equations of a knot function,
we can just use the underlying Rational.

=#


"""
    KnotParameter(param)

KnotParameter serves as the parameter of a circular curve in 3 space.

`KnotParameter`s can be added and subtracted.  They can be multiplied
by or divided by exact numbers.
"""
struct KnotParameter
    p::Rational

    KnotParameter(p::Rational) = new(mod(p, 1//1))
end

Base.zero(::KnotParameter) = KnotParameter(Rational(0))
Base.zero(::Type{KnotParameter}) = KnotParameter(Rational(0))

Base.typemin(T::Type{KnotParameter}) = zero(T)
Base.typemax(T::Type{KnotParameter}) =
    KnotParameter(Rational(1 - 1 // typemax(Int)))

Base.isless(a::KnotParameter, b::KnotParameter) =
    isless(a.p, b.p)

Base.:+(p1::KnotParameter, p2::KnotParameter) =
    KnotParameter(p1.p + p2.p)

Base.:-(p1::KnotParameter, p2::KnotParameter) =
    KnotParameter(p1.p - p2.p)

Base.convert(::Type{<:Rational}, p::KnotParameter) = p.p


Base.:*(a::Integer, p::KnotParameter) =
    KnotParameter(a * p.p)
Base.:*(p::KnotParameter, a::Integer) =
    KnotParameter(p.p * a)
Base.:*(a::Rational, p::KnotParameter) =
    KnotParameter(a * p.p)
Base.:*(p::KnotParameter, a::Rational) =
    KnotParameter(p.p * a)

Base.://(p::KnotParameter, a::Integer) =
    KnotParameter(p.p // a)
Base.://(p::KnotParameter, a::Rational) =
    KnotParameter(p.p // a)

Base.:^(p::KnotParameter, e::Integer) =
    KnotParameter(p.p ^ e)


"""
    divide_interval(from::KnotParameter, to::KnotParameter, count::Integer)

Return `count` KnotParameters evenly spaced between `from` and `to`.
"""
function divide_interval(from::KnotParameter, to::KnotParameter,
                         count::Integer)::Vector{KnotParameter}
    delta = ((to.p + ((from > to) ? 1 : 0)) - from.p) // (count + 1)
    map(1:count) do i
        KnotParameter(convert(Rational, from) + i * delta)
    end
end

