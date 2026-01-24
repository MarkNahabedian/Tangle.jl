
export KnotParameterN, KnotParameter, divide_interval

#=

KnotParameter is the type used as the parameter of a knot function.
Since a knot function defines a loop, the domain of a knot function
should identify points on a circular path.  This suggests using
something like a subtype of Unsigned or integers mod some N as the
domain.

Avoid floating point numbers because they are not exact.

WWhat do we want from arithmetic on knot parameters:

* typemin, typemax, zero

* isless, for sorting

* modular addition and subtraction.

* division of the space between two knot parameters into a specified
number of even intervals.

* convert of a KnotParameter to a fraction in the interval 0.0 to 1.0.

For generating the symbolic parametric equations of a knot function,
we can convert KnotParameter to a subtype of AbstractFloat or Rational
first.

=#


"""
    KnotParameterN(param)

KnotParameter serves as the parameter of a circular curve in 3 space.

`KnotParameter`s can be added and subtracted.  They can be multiplied
by or divided by numbers.

If `param` is a real then it is taken mod 1 and scaled by typemax(T).
"""
struct KnotParameterN{T <: Unsigned}
    p::T        # Using a UInt gives us automatic wrapped arithmetic
                # and hopefully faster arithmetic.

    KnotParameterN{T}(p::AbstractFloat) where T <: Unsigned =
        KnotParameterN{T}(Int((typemax(T) + 1) * mod(p, 1.0)))

    KnotParameterN{UInt128}(p::AbstractFloat) =
        KnotParameterN{UInt128}((BigInt(typemax(UInt128)) + 1) * mod(p, 1.0))
    
    KnotParameterN{T}(p::Rational{I}) where {T <: Unsigned, I <: Signed} =
        KnotParameterN{T}(round(Int,
                                (typemax(T) + 1) * mod(p, 1)))

    KnotParameterN{UInt128}(p::Rational{I}) where I <: Signed =
        KnotParameterN{UInt128}(round(Int,
                                (BigInt(typemax(UInt128)) + 1) * mod(p, 1)))

    KnotParameterN{T}(p::Signed) where T <: Unsigned =
        new{T}(T(typemax(T) & p))

    KnotParameterN{T}(p::T) where T <: Unsigned =
        new{T}(p)
end

Base.zero(::KnotParameterN{T}) where T <: Unsigned = KnotParameterN{T}(zero(T))
Base.zero(::Type{KnotParameterN{T}}) where T <: Unsigned = KnotParameterN{T}(zero(T))

Base.typemin(::Type{KnotParameterN{T}}) where T <: Unsigned = KnotParameterN{T}(typemin(T))
Base.typemax(::Type{KnotParameterN{T}}) where T <: Unsigned = KnotParameterN{T}(typemax(T))


Base.rem(kp1::KnotParameterN{T}, kp2::KnotParameterN{T}) where T <: Unsigned =
    KnotParameterN(rem(kp1.p, kp2.p))

#=
Base.Float64(kp::KnotParameterN{T}) where T <: Unsigned = Float64(kp.p / typemax(T))
Base.Float32(kp::KnotParameterN{T}) where T <: Unsigned = Float32(kp.p / typemax(T))
Base.Float16(kp::KnotParameterN{T}) where T <: Unsigned = Float64(kp.p / typemax(T))
=#

Base.isless(a::KnotParameterN, b::KnotParameterN) = isless(a.p, b.p)

Base.:+(p1::KnotParameterN{T}, p2::KnotParameterN{T}) where T <: Unsigned =
    KnotParameterN{T}(p1.p + p2.p)

Base.:-(p1::KnotParameterN{T}, p2::KnotParameterN{T}) where T <: Unsigned =
    KnotParameterN{T}(p1.p - p2.p)    

#=
Base.://(p1::KnotParameterN{T}, p2::KnotParameterN{T}) where T <: Unsigned =
    KnotParameterN{T}(p1.p // d)

Base.:/(p1::KnotParameterN{T}, p2::KnotParameterN{T}) where T <: Unsigned =
    KnotParameterN{T}(p1.p / d)
=#


Base.convert(::Type{<:Rational}, p::KnotParameterN{T}) where T <: Unsigned =
    p.p // (1 + typemax(T))

Base.convert(::Type{<:Rational}, p::KnotParameterN{UInt64}) =
    p.p // (1 + BigInt(typemax(UInt64)))

Base.convert(::Type{<:Rational}, p::KnotParameterN{UInt128}) =
    p.p // (1 + BigInt(typemax(UInt128)))


#=
Base.convert(::Type{<:AbstractFloat}, p::KnotParameterN{T}) where T <: Unsigned =
    p.p / (1 + BigInt(typemax(UInt64)))

Base.convert(::Type{<:AbstractFloat}, p::KnotParameterN{UInt64}) =
    p.p / (1 + BigInt(typemax(UInt64)))
=#

Base.:*(a::Signed, p::KnotParameterN{T}) where T <: Unsigned =
    KnotParameterN{T}(a * p.p)
Base.:*(p::KnotParameterN{T}, a::Signed) where T <: Unsigned =
    KnotParameterN{T}(p.p * a)
Base.:*(a::AbstractFloat, p::KnotParameterN{T}) where T <: Unsigned =
    KnotParameterN{T}(a * convert(AbstractFloat, p))
Base.:*(p::KnotParameterN{T}, a::AbstractFloat) where T <: Unsigned =
    KnotParameterN{T}(convert(AbstractFloat, p) * a)
Base.:*(a::Rational{I}, p::KnotParameterN{T}) where {T <: Unsigned, I <: Signed} =
    KnotParameterN{T}(a * convert(Rational{I}, p))
Base.:*(p::KnotParameterN{T}, a::Rational{I}) where {T <: Unsigned, I <: Signed} =
    KnotParameterN{T}(convert(Rational{I}, p) * a)

Base.://(p::KnotParameterN{T}, a::Integer) where {T <: Unsigned} =
    KnotParameterN{T}(convert(Rational{Int128}, p) // a)
Base.://(p::KnotParameterN{T}, a::Rational{I}) where {T <: Unsigned, I <: Signed} =
    KnotParameterN{T}(convert(Rational{Int128}, p) // a)

#=
Base.:/(p::KnotParameterN{T}, n::AbstractFloat) where T <: Unsigned =
    KnotParameterN{T}(convert(AbstractFloat, p) / n)
=#

Base.:^(p::KnotParameterN{T}, e::Real) where T <: Unsigned =
    KnotParameterN{T}(convert(Rational{Int64}, p.p) ^ e)

Base.isless(p::KnotParameterN{T}, e::Real) where T <: Unsigned =
    isless(p.p, KnotParameterN{T}(e).p)
Base.isless(e::Real, p::KnotParameterN{T}) where T <: Unsigned =
    isless(KnotParameterN{T}(e).p, p.p)

"""
    divide_interval(from::KnotParameterN, to::KnotParameterN, count::Integer)

Return `count` KnotParameterNs evenly spaced between `from` and `to`.
"""
function divide_interval(from::KnotParameterN{T}, to::KnotParameterN{T},
                         count::Integer)::Vector{KnotParameterN{T}} where T <: Unsigned
    delta = convert(Rational{Int64}, to - from) // (count + 1)
    map(1:count) do i
        KnotParameterN{T}(convert(Rational, from) + i * delta)
    end
end


# Pick an Unsigned size to use in most of our code:
const KnotParameter = KnotParameterN{UInt16}

