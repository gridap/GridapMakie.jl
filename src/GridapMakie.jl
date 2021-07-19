module GridapMakie

using Gridap.Visualization
using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs
using Gridap.Visualization

import Makie
import GeometryBasics

include("conversions.jl")

include("faces.jl")

include("edges.jl")

end #module