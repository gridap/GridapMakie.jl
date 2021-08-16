module GridapMakie

using Gridap
using Gridap.Helpers
using Gridap.Geometry
using Gridap.ReferenceFEs
using Gridap.Visualization

import Makie
import GeometryBasics

include("conversions.jl")

include("themes.jl")

include("recipes.jl")

end #module
