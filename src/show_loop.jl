# SOme utilities for showing and diagnosing Loops.

using Plots

export graph_loop

function graph_loop(loop::Loop; steps=16)
    points = map(loop,
                 map(KnotParameter,
                     collect((0.0 : (1.0 / steps) : 1.0))))
    plt = plot(map(p -> p[1], points),
               map(p -> p[2], points),
               map(p -> p[3], points))
end

