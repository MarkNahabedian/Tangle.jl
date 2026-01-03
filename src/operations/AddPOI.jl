export AddPOI

"""
    AddPOI(from_loop::Loop, at::KnotParameter, label)

Adds a new `PointOfInterest` to the specified `Loop` at the specified
`KnotParameter`.  The new PointOfInterest will be given the specified
`label`.  It's location will be interpolated from the `KnotParameter`.
"""
struct AddPOI <: Operation
    sequence::Integer
    from_loop::Loop
    at::KnotParameter
    label

    function AddPOI(from_loop::Loop, at::KnotParameter, label)
        new(next_op_sequence_number(),
            from_loop, at, label)
    end
end

function (op::AddPOI)()
    poi = PointOfInterest(op.at,
                          op.from_loop.knot_function(op.at)...,
                          op.label,
                          op)
    Loop([ poi, op.from_loop.poi...], op)
end

