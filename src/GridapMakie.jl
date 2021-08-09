module GridapMakie

using Gridap.Visualization
using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs
using Gridap.Visualization

import Makie
import GeometryBasics

include("conversions.jl")

include("cells.jl")

include("edges.jl")

include("vertices.jl")

end #module