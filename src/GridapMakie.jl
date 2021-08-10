module GridapMakie

using Gridap
using Gridap.Helpers
using Gridap.Geometry
using Gridap.ReferenceFEs
using Gridap.Visualization

import Makie
import GeometryBasics

include("conversions.jl")

struct PlotGrid{G<:Grid}
  grid::G
end

Gridap.Geometry.get_grid(pg::PlotGrid) = pg.grid

function setup_color(color,grid)
  color
end

function setup_color(color::AbstractArray,grid)
  if length(color) == num_cells(grid)
    to_dg_cell_values(grid,color)
  elseif length(color) == num_nodes(grid)
    to_dg_node_values(grid,color)
  else
    @unreachable
  end
end

function Makie.plot!(p::Makie.Mesh{<:Tuple{PlotGrid}})
  grid = Makie.lift(get_grid,p[1])
  color = Makie.lift(setup_color,p[:color],grid)
  shading = p[:shading]
  colormap=p[:colormap]
  #TODO delegate the other attributes of mesh!
  D = num_cell_dims(grid[])
  if D in (2,3)
    mesh = Makie.lift(g->g|>to_face_grid|>to_plot_mesh,grid)
    Makie.mesh!(p,mesh;color=color,shading=shading,colormap=colormap)
  elseif D == 1
    mesh = Makie.lift(to_plot_mesh,grid)
    linewidth = p[:linewidth]
    Makie.linesegments!(p,mesh;color=color,colormap=colormap,shading=shading,linewidth=linewidth)
  elseif D == 0
    mesh = Makie.lift(to_plot_mesh,grid)
    Makie.scatter!(p,mesh;color=color,shading=shading,colormap=colormap)
  else
    @unreachable
  end
  p
end

function Makie.convert_arguments(::Type{<:Makie.Wireframe}, pg::PlotGrid)
  grid = get_grid(pg)
  # TODO use to_mesh instead of to_plot_mesh
  mesh = to_plot_mesh(grid)
  (mesh,)
end

function Makie.convert_arguments(::Type{<:Makie.Scatter}, pg::PlotGrid)
  grid = get_grid(pg)
  node_coords = get_node_coordinates(grid)
  x = map(to_point,node_coords)
  (x,)
end

# TODO use to_grid instead of calling visualization_data

function Makie.convert_arguments(::Type{<:Makie.Mesh}, trian::Triangulation)
  vds = visualization_data(trian,"")
  grid = first(vds).grid
  (PlotGrid(grid),)
end

function Makie.convert_arguments(t::Type{<:Makie.Wireframe}, trian::Triangulation)
  vds = visualization_data(trian,"")
  grid = first(vds).grid
  Makie.convert_arguments(t,PlotGrid(grid))
end

function Makie.convert_arguments(t::Type{<:Makie.Scatter}, trian::Triangulation)
  vds = visualization_data(trian,"")
  grid = first(vds).grid
  Makie.convert_arguments(t,PlotGrid(grid))
end

Makie.plottype(trian::Triangulation) = Makie.Mesh

@Makie.recipe(MeshField,trian,uh) do scene
    Makie.Attributes(;
      shading = false,
      linewidth = 2,
      colormap = :viridis,
    )
end

function Makie.plot!(p::MeshField)
  # TODO this is not reactive
  trian = p[:trian][]
  uh = p[:uh][]
  vds = visualization_data(
    trian,"",cellfields=[""=>uh])
  grid = first(vds).grid
  nodaldata = first(first(vds).nodaldata)[2]
  scalarnodaldata = map(to_scalar,nodaldata)
  #TODO delegate more attributes
  Makie.mesh!(p,PlotGrid(grid);
    color=scalarnodaldata,
    shading=p[:shading],
    linewidth=p[:linewidth],
    colormap=p[:colormap])
  p
end

Makie.plottype(trian::Triangulation,f) = MeshField

#include("cells.jl")
#
#include("edges.jl")
#
#include("vertices.jl")

end #module
