```@meta
CurrentModule = Tangle
```

# Tangle

Tangle is an attempt at software for describing, modeling and working
with knots.


## Representation

The basic data structure is a `Loop`.  Among other things, a `Loop` is
a function that maps a `KnotParameter` to a point in three dimensional
space.

A `KnotParameter` is a floating poingt number ranging from `0.0`
(`MIN_KnotParameter`) to `1.0` (`MAX_KnotParameter`).  Arithmetic on
`KnotParameter`s is performed modulo `1.0`.

A loop is defined by a sequence of ":points of interest".  Each
`PointOfIntrerest` assiciates a `KnotParameter` with a point in space.


```@docs
KnotParameter
Tangle.divide_interval
PointOfInterest
PointsOfInterest
Loop
find_poi
next
previous
before
after
Tangle.LoopSegmentIterator
```


## Operations

```@docs
grab
was
reidemeisterTwist
```


## Geometry

```@docs
center
Tangle.Line
Tangle.direction_vector
Tangle.unit_direction_vector
Tangle.parallel
Tangle.point_on_line
Tangle.point_in_segment
Tangle.proximal_points
```


## Symbolics.jl

Portions of Tangle use Symbolics.jl.  Some utilities have been defined
to make it easier to use vectors in Symbolics.jl.

```@docs
Tangle.symbolic_vector
Tangle.vsubs
```


## Everything

```@autodocs
Modules = [ Tangle ]
```
