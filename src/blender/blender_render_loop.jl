using JSON

export render_loop_in_blender

BLENDER_TEMP_DIR = abspath(joinpath(@__DIR__, "tempfiles"))


function render_loop_in_blender(loop, filename_base)
    coords = loop_points_for_graph(loop, 3)
    mkpath(BLENDER_TEMP_DIR)
    json_file = joinpath(BLENDER_TEMP_DIR, filename_base * ".json")
    open(json_file, "w") do io
        JSON.print(io, coords)
    end
    blender_command_path = "/Applications/Blender.app/Contents/MacOS/Blender"
    render_script = abspath(joinpath(@__DIR__, "render_loop.py"))
    run(`$blender_command_path -b -P $render_script -- $json_file`
        ;
        wait=true)
end

