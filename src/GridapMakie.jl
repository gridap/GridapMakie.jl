module GridapMakie

using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs
using Gridap.Visualization

import Makie
import GeometryBasics

include("conversions.jl")

include("vertices.jl")

include("edges.jl")

include("cells.jl")

end #module