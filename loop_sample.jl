using Tangle

loop = Loop()
show_points(loop)
# graph_loop(loop)

gloop, gpoi = grab(loop, :east, -0.8, :grab1)
show_points(gloop)
# graph_loop(gloop)

r1loop, rop = reidemeisterTwist(grab(loop, KnotParameter(0.1), 1, :r1)...,
                                RightTwist())
show_points(r1loop)
graph_loop(r1loop)

