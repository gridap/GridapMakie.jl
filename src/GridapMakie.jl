module GridapMakie

using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs

import Makie
import GeometryBasics

function GeometryBasics.Mesh(grid::Grid)
    GeometryBasics.Mesh(UnstructuredGrid(grid))
end

function GeometryBasics.Mesh(grid::UnstructuredGrid)  
    xs = get_node_coordinates(grid)
    Tp = eltype(eltype(xs))
    D = length(eltype(xs))
    ps = collect(reinterpret(GeometryBasics.Point{D,Tp},xs))
    cns = get_cell_node_ids(grid)
    Tf = eltype(eltype(cns))
    fs = collect(lazy_map(GeometryBasics.NgonFace{D+1,Tf},cns))
    return GeometryBasics.Mesh(GeometryBasics.connect(ps,fs))
end

Makie.convert_arguments(::Type{<:Makie.Mesh},grid::UnstructuredGrid) = (GeometryBasics.Mesh(grid),)

Makie.convert_arguments(::Type{<:Makie.Wireframe},grid::UnstructuredGrid) = (GeometryBasics.Mesh(grid),)

end #module