mport bpy
import json
import sys

# Get coordinates from Julia (passed after the '--' flag)
data_path = sys.argv[-1]
with open(data_path, 'r') as f:
    coords = json.load(f)

# Clear scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Create Curve
curve_data = bpy.data.curves.new("JuliaPath", type='CURVE')
curve_data.dimensions = '3D'
curve_data.bevel_depth = 0.2  # Set diameter here
spline = curve_data.splines.new('POLY')
spline.points.add(len(coords) - 1)

for i, pt in enumerate(coords):
    spline.points[i].co = (pt[0], pt[1], pt[2], 1)

obj = bpy.data.objects.new("Path", curve_data)
bpy.context.collection.objects.link(obj)

# Save result
bpy.ops.wm.save_as_mainfile(filepath="output.blend")

