export UNKNOT, ONE_CROSSING,
    THREE_LINKED_LOOPS, BORROMEAN_RINGS,
    TREFOIL, SQUARE_KNOT

UNKNOT = Loop()


### One Crossing:

ONE_CROSSING =
    StyledLoop("one_crossing",
               let
                   op = NoOp()
                   Loop([
                       PointOfInterest(KnotParameter(0//8),     -2,  0,  0,   :left, op),
                       PointOfInterest(KnotParameter(1//8),     -1,  1,  0,   :point2, op),
                       PointOfInterest(KnotParameter(2//8),      0,  0,  1/2, :cross1a, op),
                       PointOfInterest(KnotParameter(3//8),      1, -1,  0,   :point4, op),
                       PointOfInterest(KnotParameter(4//8),      2,  0,  0,   :right, op),
                       PointOfInterest(KnotParameter(5//8),      1,  1,  0,   :point6, op),
                       PointOfInterest(KnotParameter(6//8),      0,  0, -1/2, :cross1b, op),
                       PointOfInterest(KnotParameter(7//8),     -1, -1,  0,   :point8, op),
                       PointOfInterest(typemax(KnotParameter), -2,  0,  0,   :end, op)
                   ], op)
               end,
               (0, 1, 0, 1),
               0.2)


### Three Linked Loops:

THREE_LINKED_LOOPS = let
    tilted = let
        # PointsOfInterest for a flat unit circle:
        unit_circle = let
            knot_parameters = map(n -> KnotParameter(n//4), 0:3)
            labels = ["start", "1stQuarter", "halfway", "3rdQuarter"]
            unit_circle = map(knot_parameters) do kp
                a = float(kp.p) * 2 * pi
                [ cos(a), sin(a), 0 ]
            end
            [ map(zip(knot_parameters, unit_circle, labels)) do (kp, xyz, label)
                 PointOfInterest(kp, xyz..., label, NoOp(), false)
              end...,
              PointOfInterest(typemax(KnotParameter),
                              unit_circle[1]...,
                              "end",
                              NoOp(),
                              false)
              ]
        end
        # PointsOfInterest for a tilted unit circle:
        map(LinearMap(RotY(pi / 4)), unit_circle)
    end
    diameter = 0.1
    operation = NoOp()
    names = map(n -> "loop$n", 1:3)
    colors = [ [ 1, 0, 0, 1],
               [ 0, 1, 0, 1 ],
               [ 0, 0, 1, 1 ] ]
    rotations = map(angle -> LinearMap(RotZ(angle)),
                    2 * pi * (0:2) / 3 )
    tl = Translation(0.25, 0.25, 0)
    map(zip(names, rotations, colors)) do (name, zrot, color)
        loop = Loop((zrot ∘ tl).(tilted), operation)
        StyledLoop(name, loop, color, diameter)
    end
end

BORROMEAN_RINGS = let
    op = NoOp()
    major_diameter = 8
    minor_diameter = 6
    points = [ [ major_diameter, 0, 0 ],
               [ 0, minor_diameter, 0 ],
               [ - major_diameter, 0, 0 ],
               [ 0, - minor_diameter, 0 ] ]
    names = map(n -> "loop$n", 1:3)
    coordinate_permutation = [ [ 1, 2, 3 ],
                               [ 3, 1, 2 ],
                               [ 2, 3, 1 ] ]
    colors = [ [ 1, 0, 0, 1],
               [ 0, 1, 0, 1 ],
               [ 0, 0, 1, 1 ] ]
    map(zip(1:3, names, coordinate_permutation, colors)) do (i, name, permutation, color)
        permute(point) = point[permutation]
        permuted = map(permute, points)
        denominator = length(permuted)
        poi = [ map(zip(0 : (length(permuted) - 1),
                        permuted)) do (kpn, point)
                            PointOfInterest(KnotParameter(kpn // length(permuted)),
                                            point...,
                                            """$(name)_$(join(point, "_"))""",
                                            op)
                        end ...,
                PointOfInterest(typemax(KnotParameter),
                                first(permuted)...,
                                "close", op)
                ]
        loop = Loop(poi, op)
        StyledLoop("borromean_ring$i", loop, color, 0.1)
    end
end

TREFOIL = let
    op = NoOp()
    points = Dict()
    xmax = 3
    ymax = 4
    points[:top] = [ 0, ymax, 0 ]
    points[:bottom] = [ 0, -ymax, 0 ]
    points[:ulcurve] = [ -xmax, 2, 0 ]
    points[:urcurve] = [ xmax, 2, 0 ]
    points[:llcurve] = [ -xmax, -2, 0 ]
    points[:lrcurve] = [ xmax, -2, 0 ]
    points[:cp1] = [ -2, 0, 0 ]
    points[:middle12u] = [-1, 1, 0 ]
    points[:middle12l] = [-1, -1, 0 ]
    points[:cp2] = [ 0, 0, 0 ]
    points[:middle23u] = [1, 1, 0 ]
    points[:middle23l] = [1, -1, 0 ]    
    points[:cp3] = [ 2, 0, 0 ]
    z0(symb) = (points[symb], symb)
    over(symb) = (points[symb] + [ 0, 0, 1 ], string(symb) * "over")
    under(symb) = (points[symb] + [ 0, 0, -1 ], string(symb) * "under")
    cploop(cp1, cp2, yoffset) = ((points[cp1] + points[cp2])//2 + [ 0, yoffset, 0 ],
                                 string(cp1) * "-" * string(cp2))
    visits = [
        z0(:top), z0(:ulcurve),
        under(:cp1),
        cploop(:cp1, :cp2, -1),
        over(:cp2),
        cploop(:cp2, :cp3, 1),
        under(:cp3),
        z0(:lrcurve), z0(:bottom), z0(:llcurve),
        over(:cp1),
        cploop(:cp1, :cp2, 1),
        under(:cp2),
        cploop(:cp2, :cp3, -1),
        over(:cp3),
        z0(:urcurve)
    ]
    params = 0//1 : (1//length(visits)) : 1//1
    StyledLoop("trefoil",
               Loop([
                   map(params, visits) do p, (coords, label)
                       PointOfInterest(KnotParameter(p), coords..., label, op)
                   end...,
                   PointOfInterest(typemax(KnotParameter), points[:top]..., :end, op)
                   ], op),
               (0, 1, 0, 1),
               0.2)
end


SQUARE_KNOT = let
    op = NoOp()
    points = Dict()
    xmax = 6
    ymax = 6
    points[:top] =     [ 0,      ymax,       0 ]
    points[:bottom] =  [ 0,     -ymax,       0 ]
    points[:ulcurve] = [ -xmax,  ymax * 2/3, 0 ]
    points[:urcurve] = [  xmax,  ymax * 2/3, 0 ]
    points[:llcurve] = [ -xmax, -ymax * 2/3, 0 ]
    points[:lrcurve] = [  xmax, -ymax * 2/3, 0 ]
    points[:cp1] = [ -2, 2, 0 ]
    points[:cp2] = [  0, 2, 0 ]
    points[:cp3] = [  2, 2, 0 ]
    points[:rightbend] = [ 3, 0, 1 ]
    points[:cp4] = [ -2, -2, 0 ]
    points[:cp5] = [  0, -2, 0 ]
    points[:cp6] = [  2, -2, 0 ]
    points[:leftbend] = [ -3, 0, -1 ]
    z0(symb) = (points[symb], symb)
    over(symb) = (points[symb] + [ 0, 0, 1 ], string(symb) * "over")
    under(symb) = (points[symb] + [ 0, 0, -1 ], string(symb) * "under")
    cploop(cp1, cp2, yoffset) = ((points[cp1] + points[cp2])//2 + [ 0, yoffset, 0 ],
                                 string(cp1) * "-" * string(cp2))
    visits = [
        z0(:top), z0(:ulcurve),
        over(:cp1),
        cploop(:cp1, :cp2, -1),
        under(:cp2),
        cploop(:cp2, :cp3, 1),
        over(:cp3),
        z0(:rightbend),
        over(:cp6),
        cploop(:cp6, :cp5, -1),
        under(:cp5),
        cploop(:cp5, :cp4, 1),
        over(:cp4),
        z0(:llcurve), z0(:bottom), z0(:lrcurve),
        under(:cp6),
        cploop(:cp6, :cp5, 1),
        over(:cp5),
        cploop(:cp5, :cp4, -1),
        under(:cp4),
        z0(:leftbend),
        under(:cp1),
        cploop(:cp1, :cp2, 1),
        over(:cp2),
        cploop(:cp2, :cp3, -1),
        under(:cp3),
        z0(:urcurve)
    ]
    params = 0//1 : (1//length(visits)) : 1//1
    StyledLoop("square_knot",
               Loop([
                   map(params, visits) do p, (coords, label)
                       PointOfInterest(KnotParameter(p), coords..., label, op)
                   end...,
                   PointOfInterest(typemax(KnotParameter), points[:top]..., :end, op)
                   ], op),
               (0, 1, 0, 1),
               0.2)
end

