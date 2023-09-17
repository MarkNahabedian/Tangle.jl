# SOme utilities for showing and diagnosing Loops.

using Plots: plot, plot!, annotate!

export show_points, flat_graph_loop, graph_loop

function show_points(loop::Loop)
    println()
    for poi in loop.poi
        @printf("%10.7f\t%6.3f\t%7.3f\t%7.3f\t%s\n",
                poi.p, poi.x, poi.y, poi.z, poi.label)
    end
    println()
end

function loop_points_for_graph(loop::Loop, steps_between_poi)
    kps = Set()
    for poi in loop.poi
        npoi = next(loop, poi)
        for f in (poi.p.p) : ((npoi.p.p - poi.p.p) / steps_between_poi) : (npoi.p.p)
            push!(kps, KnotParameter(f))
        end
    end
    return map(sort(collect(kps))) do kp
        spatial_coordinates(loop(kp))
    end
end

function flat_graph_loop(loop::Loop; steps_between_poi=4)
    points = loop_points_for_graph(loop, steps_between_poi)
    plt = plot(map(p -> p[1], points),
               map(p -> p[2], points),
               background = :black,
               linewidth = 4)
    # Overlay points of interest
    let
        x = map(poi -> poi.x, loop.poi)
        y = map(poi -> poi.y, loop.poi)
        labels = map(poi -> string(poi.label), loop.poi)
        plot!(x, y,
              background = :black,
              linewidth = 0,
              markershape = :circle)
        annotate!(x, y, labels)
    end
end

function graph_loop(loop::Loop; steps_between_poi=4)
    points = loop_points_for_graph(loop, steps_between_poi)
    plt = plot(map(p -> p[1], points),
               map(p -> p[2], points),
               map(p -> p[3], points),
               background = :black,
               linewidth = 4)
    # Overlay points of interest
    let
        x = map(poi -> poi.x, loop.poi)
        y = map(poi -> poi.y, loop.poi)
        z = map(poi -> poi.z, loop.poi)
        labels = map(poi -> string(poi.label), loop.poi)
        plot!(x, y, z,
              background = :black,
              linewidth = 0,
              markershape = :circle)
        annotate!(x, y, z, labels)
    end
end


#=

Here are the steps on how to do it:

Open Blender and create a new file.

In the Object menu, select "Curve" > "Bezier".

In the 3D View, click and drag to create a new Bezier curve.

In the Properties panel, under the "Geometry" tab, set the
"Resolution" to a high enough value to smooth out the curve.

In the "Points" tab, enter the coordinates of the points that describe
the curve.

Select the first and last points of the curve and press "Ctrl" + "E"
to join them.

Switch to the "Object" mode and press "Tab" to enter Edit mode.

Move the control points of the curve to adjust its shape.

Press "Tab" to exit Edit mode.

The curve should now be visible in the 3D View.

You can also render the curve to create a 2D image of it. To do this,
go to the Render menu and select "Render Image". In the Render Image
dialog box, select the "Curve" output type and click on the "Render"
button.

I hope this helps! Let me know if you have any other questions.

-------

Yes, you can programmatically generate a file that you can open in Blender to visualize a closed 3D curve. There are many different programming languages that you can use to do this, but Python is a popular choice.

Here is an example of a Python script that you can use to generate a file that can be opened in Blender to visualize a closed 3D curve:

Python
import bpy

# Define the points that describe the curve.
points = [(1, 0, 0), (2, 1, 0), (3, 2, 0), (2, 3, 0), (1, 2, 0)]

# Create a new Bezier curve object.
curve = bpy.ops.curve.primitive_bezier_curve_add()

# Set the points of the curve.
curve.points = points

# Set the resolution of the curve.
curve.resolution = 100

# Save the file.
bpy.ops.export_scene.obj(filepath="curve.obj")

Use code with caution. Learn more

This script will create a file called curve.obj that can be opened in
Blender. When you open the file in Blender, you will see a Bezier
curve that follows the points that you specified in the script.

You can also use other programming languages to generate files that
can be opened in Blender. For example, you can use C++, Java, or
JavaScript. The specific language that you choose will depend on your
preferences and the programming environment that you are familiar
with.

I hope this helps!

------

Yes, you can write an OBJ file from Julia. Here is an example of how you can do it:

Julia
using MeshIO

# Define the points that describe the curve.
points = [(1, 0, 0), (2, 1, 0), (3, 2, 0), (2, 3, 0), (1, 2, 0)]

# Create a new OBJ file.
obj = MeshIO.OBJFile("curve.obj")

# Add the vertices to the file.
obj.add_vertices(points)

# Add the faces to the file.
for i in 1:4
    obj.add_face([i, i+1, i+2])
end

# Save the file.
obj.write()

Use code with caution. Learn more

This code will create a file called curve.obj that contains the
vertices and faces of the Bezier curve. You can open this file in
Blender to visualize the curve.

Here is a breakdown of the code:

The first line imports the MeshIO package, which provides functions
for working with OBJ files.

The second line defines the points that describe the curve.

The third line creates a new OBJ file.

The fourth line adds the vertices to the file.

The fifth line adds the faces to the file.

The sixth line saves the file.

I hope this helps!

------

Here is an example of how you can use the NURBSCurve node to create a
cubic spline in VRML:

XML
<NURBSCurve id="myCurve"
        controlPoints="1 0 0, 2 1 0, 3 2 0, 2 3 0, 1 2 0"
        degree="3"/>

This code will create a cubic spline with five control points. The
control points are specified in the controlPoints attribute. The
degree of the spline is specified in the degree attribute.

You can also use the knots attribute to specify the knots of the
spline. The knots are used to control the smoothness of the curve at
the ends.

Here is an example of how you can use the knots attribute to create a
cubic spline with smoother ends:

XML
<NURBSCurve id="myCurve"
        controlPoints="1 0 0, 2 1 0, 3 2 0, 2 3 0, 1 2 0"
        degree="3"
        knots="0 0 0 1 1 1"/>

This code will create a cubic spline with the same control points as
the previous example, but the knots are specified as 0, 0, 0, 1, 1,
1. This will make the curve smoother at the ends.

=#

#=
using MeshIO

function loop_to_obj(loop::Loop, filename)
    obj = MeshIO.OBJFile(filename)
    obj.add_vertices(map(spatial_coordinates, loop.poi))
    
    obj.write()
end
=#

