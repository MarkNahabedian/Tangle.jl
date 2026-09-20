import bpy
import json
import sys
from pathlib import Path


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    pass


def read_json_file(file):
  with open(file, 'r') as f:
    return json.load(f)


def make_material_for_color(color):
    r, g, b, a = color
    name = "loop_color_%d_%d_%d_%d" % (r, g, b, a)
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    mat.diffuse_color = (r, g, b, a)
    return mat


def create_path_from_styled_loop(sloop):
    curve_data = bpy.data.curves.new(sloop["name"], type='CURVE')
    curve_data.dimensions = '3D'
    curve_data.bevel_depth = sloop["diameter"]
    spline = curve_data.splines.new('POLY')
    spline.points.add(len(sloop["coords"]) - 1)
    for i, pt in enumerate(sloop["coords"]):
        spline.points[i].co = (pt[0], pt[1], pt[2], 1)
        pass
    curve_data.materials.append(make_material_for_color(sloop["color"]))
    return bpy.data.objects.new("Path", curve_data)


def render_styled_loops_from_file(file):
    json = read_json_file(file)
    clear_scene()
    paths = [ create_path_from_styled_loop(l)
              for l in json ]
    for obj in paths:
        bpy.context.collection.objects.link(obj)
        pass
    bpy.ops.wm.save_as_mainfile(filepath=str(Path(file).with_suffix(".blend")))
    pass

if __name__ == "__main__":
    render_styled_loops_from_file(sys.argv[-1])
    pass

