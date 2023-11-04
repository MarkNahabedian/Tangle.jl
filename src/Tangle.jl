module Tangle

using DataStructures
using InteractiveUtils
import StaticArrays

include("utils.jl")
include("symbolics_vector_variables.jl")
include("geometry.jl")
include("knot_parameter.jl")
include("point_of_interest.jl")
include("loop.jl")
include("operations/grab.jl")
include("operations/reidermeister_1.jl")
include("show_loop.jl")

# include("vector_utils.jl")
# include("strand.jl")
# include("reidermeister.jl")

# include("links.jl")

end
