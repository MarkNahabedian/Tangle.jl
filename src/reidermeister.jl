# Reidermeister moves.

export reidermeisterTwistRight, reidermeisterTwistLeft

function reidermeisterTwist(strand::Strand, p, x, y, handedness)
    before, after = nearest(strand, p)
    if before != nothing && after != nothing
        between(a, b) = (a + b) / 2
        middle = between(before.p, after.p)
        p1 = between(middle, before.p)
        p2 = between(middle, after.p)
    else
        if before == nothing
            p1 = p - 1
        end
        if after == nothing
            p2 = p + 1
        end
    end
    if handedness < 0
        p1,p2 = p2, p1
    end
    # Should we introduce a point between p1 and p2 that is some
    # distance from x, y to establisgh the size of the loop?
    cross(strand, p1, strand, p2, x, y)
end

"""
Perform a Reidermeister right hand twist.
Returns the two StrandPoints at the new crossing.
"""
function reidermeisterTwistRight(strand, p, x, y)::Tuple{StrandPoint, StrandPoint}
    reidermeisterTwist(strand, p, x, y, 1)
end

"""
Perform a Reidermeister left hand twist.
Returns the two StrandPoints at the new crossing.
"""
function reidermeisterTwistLeft(strand, p, x, y)::Tuple{StrandPoint, StrandPoint}
    reidermeisterTwist(strand, p, x, y, -1)
end
