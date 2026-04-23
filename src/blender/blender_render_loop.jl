using JSON

export render_loop_in_blender, StyledLoop, blender_render_loops

BLENDER_TEMP_DIR = abspath(joinpath(@__DIR__, "tempfiles"))


function render_loop_in_blender(loop::Loop, filename_base)
    coords = loop_points_for_graph(loop, 3)
    mkpath(BLENDER_TEMP_DIR)
    json_file = joinpath(BLENDER_TEMP_DIR, filename_base * ".json")
    open(json_file, "w") do io
        JSON.print(io, coords, 4)
    end
    blender_command_path = "/Applications/Blender.app/Contents/MacOS/Blender"
    render_script = abspath(joinpath(@__DIR__, "render_loop.py"))
    run(`$blender_command_path -b -P $render_script -- $json_file`
        ;
        wait=true)
end


struct StyledLoop
    name::AbstractString
    loop::Loop
    color          # Tuple of red, green, blue, alpha values from 0 to 1.
    diameter
end

blender_render_loops(sloop::StyledLoop, filename_base::String; kwargs...) =
    blender_render_loops([sloop], filename_base; kwargs...)

function blender_render_loops(loops::Vector{StyledLoop},
                              filename_base::String;
                              knot_function_type::Type{<:KnotFunction} = DEFAULT_KNOT_IMPLEMENTATION,
                              steps_between_poi::Int = 3)
    mkpath(BLENDER_TEMP_DIR)
    json_file = joinpath(BLENDER_TEMP_DIR, filename_base * ".json")
    open(json_file, "w") do io
        JSON.print(io,
                   map(loops) do styled_loop
                       OrderedDict(
                           "_TYPE_" => "StyledLoop",
                           "name" => styled_loop.name,
                           "color" => styled_loop.color,
                           "diameter" => styled_loop.diameter,
                           "coords" => loop_points_for_graph(styled_loop.loop,
                                                             steps_between_poi;
                                                             knot_function_type=knot_function_type)
                       )
                   end,
                   4)
    end
    blender_command_path = "/Applications/Blender.app/Contents/MacOS/Blender"
    render_script = abspath(joinpath(@__DIR__, "render_styled_loops.py"))
    run(`$blender_command_path -b -P $render_script -- $json_file`
        ;
        wait=true)
end

