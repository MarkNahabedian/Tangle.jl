module Tangle

using DataStructures
using InteractiveUtils
using CoordinateTransformations
using CoordinateTransformations: LinearMaps
using Rotations
import StaticArrays
using PropertyMethods

export is_running_on_github

is_running_on_github() = get(ENV, "CI", "false") == "true"


include("utils.jl")
include("symbolics_vector_variables.jl")
include("geometry.jl")
include("knot_parameter.jl")

include("operations.jl")

include("point_of_interest.jl")
include("loop.jl")

include("operations/AddPOI.jl")

include("operations/grab.jl")
include("operations/reidermeister_1.jl")
include("show_loop.jl")
include("blender/blender_render_loop.jl")
include("blender/test_loops.jl")

include("vector_utils.jl")

include("symbolic_cubic_splines.jl")

# include("strand.jl")
# include("reidermeister.jl")

# include("links.jl")

end
