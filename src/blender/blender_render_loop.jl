using JSON

export render_loop_in_blender

LOOP_COORDINATES_TEMP_FILE = abspath(joinpath(@__DIR__, "loop_coords.jl"))


function render_loop_in_blender(loop)
    coords = loop_points_for_graph(loop, 3)
    open(LOOP_COORDINATES_TEMP_FILE, "w") do io
        JSON.print(io, coords)
    end
    blender_command_path = "/Applications/Blender.app/Contents/MacOS/Blender"
    render_script = abspath(joinpath(@__DIR__, "render_loop.py"))
    run(`$blender_command_path -b -P $render_script -- $LOOP_COORDINATES_TEMP_FILE`
        ;
        wait=true)
end

