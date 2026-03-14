
### One Crossing:

one_crossing =
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
    end

ocsl = StyledLoop("one_crossing",
                  one_crossing,
                  (0, 1, 0, 1),
                  0.2)

# blender_render_loops(ocsl, "one_crossing_styled")


### Three Linked Loops:

three_linked_loops = let
    tilted = let
        # PointsOfInterest for a flat unit circle:
        unit_circle = let
            knot_parameters = [ map(n -> KnotParameter(n//4), 0:3)...,
                                typemax(KnotParameter) ]
            labels = ["start", "1stQuarter", "halfway", "3rdQuarter", "end"]
            unit_circle = map(knot_parameters) do kp
                a = float(kp.p) * 2 * pi
                [ cos(a), sin(a), 0 ]
            end
            map(zip(knot_parameters, unit_circle, labels)) do (kp, xyz, label)
                PointOfInterest(kp, xyz..., label, NoOp(), false)
            end
        end
        map(LinearMap(RotY(pi / 6)), unit_circle)
    end
    diameter = 0.1
    operation = NoOp()
    names = map(n -> "loop$n", 1:3)
    colors = [ [ 1, 0, 0, 1],
               [ 0, 1, 0, 1 ],
               [ 0, 0, 1, 1 ] ]
    rotations = map(angle -> LinearMap(RotZ(angle)),
                    2 * pi * (0:2) / 3 )
    tl = Translation(0.3, 0.3, 0)
    map(zip(names, rotations, colors)) do (name, zrot, color)
        loop = Loop((zrot ∘ tl).(tilted), operation)
        StyledLoop(name, loop, color, diameter)
    end
end

# blender_render_loops(Tangle.three_linked_loops, "three_linked_loops")




#=
# Square Knot

let
square_knot_loops =
    let
        op = NoOp()
        cp1xy = [-1, 1]
        cp2xy = [0, 1]
        cp3xy = [1, 1]
        cp4xy = [1, -1]
        cp5xy = [0, -1]
        cp6xy = [-1, -1]
        inter_cp_offset = [0, 0.25]
        mid(cp1, cp2) = (cp1 + cp2) / 2
        square_knot_loop1 = let
            points = [
                [-4, 0, 0,   :left],
                [cp1xy..., 0.25, :cp1_a],
                [(mid(cp1xy, cp2xy) - inter_cp_offset)..., 0, ""],
                [cp2xy..., -0.25, :cp2_a],
                [(mid(cp2xy, cp3xy) + inter_cp_offset)..., 0, ""],
                [cp3xy..., 0.25, :cp3_a],
                [2, 0, 0, :loop],
                [cp4xy..., 0.25, :cp4a],
                [(mid(cp4xy, cp5xy) - inter_cp_offset)..., 0, ""],
                [cp5xy..., -0.25, :cp5a],
                [(mid(cp5xy, cp6xy) + inter_cp_offset)..., 0, ""],
                [cp6xy..., 0.25, :cp6a],
                [-4, 0, 0, :left2]
            ]
            Loop(map(enumerate(points)) do i, p
                     x, y, z, name = p
                     PointOfInterest(KnotParameter((i - 1) // length(points)),
                                     x, y, z, name, op)
                 end), op
        end
        square_knot_loop2 = let
            points = [
                [4, 0, 0,   :right],
                [cp4xy..., -0.25, :cp4_b],
                [(mid(cp4xy, cp5xy) + inter_cp_offset)..., 0, ""],
                [cp5xy..., 0.25, :cp5_b],
                [(mid(cp5xy, cp6xy) - inter_cp_offset)..., 0, ""],
                [cp6xy..., -0.25, :cp6_b],
                [-2, 0, 0, :loop],
                [cp1xy..., -0.25, :cp1_b],
                [(mid(cp1xy, cp2xy) + inter_cp_offset)..., 0, ""],
                [cp2xy..., 0.25, :cp2_b],
                [(mid(cp2xy, cp3xy) - inter_cp_offset)..., 0, ""],
                [cp3xy..., -0.25, :cp3_b],
                [4, 0, 0, :right2]
            ]
            Loop(map(enumerate(points)) do i, p
                     x, y, z, name = p
                     PointOfInterest(KnotParameter((i - 1) // length(points)),
                                     x, y, z, name, op)
                 end), op

        end
        [square_knot_loop1, square_knot_loop2]
    end

=#

