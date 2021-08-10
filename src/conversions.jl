#Makie.convert_arguments(::Type{<:Makie.Mesh}, grid::Grid) = ( grid |> to_plot_mesh, )
#Makie.convert_arguments(::Type{<:Makie.Wireframe}, grid::Grid) = ( grid |> to_plot_mesh, )
#Makie.convert_arguments(::Makie.PlotFunc, grid::Grid) = ( grid |> to_plot_mesh, )

# Overload plot from Makie for Triangulation and CellField types:
Makie.plottype(::Union{Triangulation, CellField}) = Cells{<:Tuple{Union{Triangulation, CellField}}}
Makie.plottype(::Triangulation, ::CellField) = Cells{<:Tuple{Triangulation, CellField}}
Makie.plottype(::Union{BoundaryTriangulation, SkeletonTriangulation}) = Edges{<:Tuple{Union{BoundaryTriangulation, SkeletonTriangulation}}}
Makie.plottype(::BoundaryTriangulation, ::CellField) = Edges{<:Tuple{BoundaryTriangulation, CellField}}
Makie.plottype(::SkeletonTriangulation, ::CellField) = Edges{<:Tuple{SkeletonTriangulation, CellField}}

function to_plot_mesh(grid::Grid)
  UnstructuredGrid(grid) |> to_plot_mesh
end

function to_plot_mesh(grid::CartesianGrid)
  simplexify(grid) |> to_plot_mesh
end

# TODO rename to to_plot_dg_mesh
function to_plot_mesh(grid::UnstructuredGrid)
  if num_cell_dims(grid) == 2
    #to_boundary_grid(grid) |> to_simplex_grid |> to_dg_mesh |> GeometryBasics.normal_mesh
    to_simplex_grid(grid) |> to_dg_mesh |> GeometryBasics.normal_mesh
  else
    to_simplex_grid(grid) |> to_dg_mesh
  end
end

#function to_plot_mesh(grid::UnstructuredGrid)
#  if num_cell_dims(grid) == 2
#    #to_boundary_grid(grid) |> to_simplex_grid |> to_dg_mesh |> GeometryBasics.normal_mesh
#    to_simplex_grid(grid) |> to_mesh |> GeometryBasics.normal_mesh
#  else
#    to_simplex_grid(grid) |> to_mesh
#  end
#end
#
# function to_mesh(grid::UnstructuredGrid)
# end

function to_simplex_grid(grid)
  reffes = get_reffes(grid)
  polys = map(get_polytope,reffes)
  all(is_simplex,polys) ? grid : simplexify(grid)
end

function to_point(x::VectorValue{D,T}) where {D,T}
  GeometryBasics.Point{D,T}(Tuple(x))
end

function to_dg_points(grid::UnstructuredGrid)
  node_x = get_node_coordinates(grid)
  coords = to_dg_node_values(grid, node_x)
  [to_point(x) for x in coords]
end

function to_dg_mesh(grid::UnstructuredGrid)
  ps = to_dg_points(grid)
  Dc = num_cell_dims(grid)
  Tc = Int32
  cns = Vector{Vector{Tc}}(undef, num_cells(grid))
  i = 1
  for cell in 1:num_cells(grid)
    cn = zeros(Tc, Dc+1)
    for lnode in 1:(Dc+1)
      cn[lnode] = i
      i += one(Tc)
    end
    cns[cell] = cn
  end
  fs = lazy_map(GeometryBasics.NgonFace{Dc+1,Tc}, cns) |> collect
  GeometryBasics.connect(ps, fs) |> GeometryBasics.Mesh
end

function to_dg_node_values(grid::Grid, node_value::Vector)
  cell_nodes = get_cell_node_ids(grid)
  i = 0
  cache = array_cache(cell_nodes)
  for cell in 1:length(cell_nodes)
    nodes = getindex!(cache, cell_nodes, cell)
    for node in nodes
      i += 1
    end
  end
  T = eltype(node_value)
  values = zeros(T,i)
  i = 0
  for cell in 1:length(cell_nodes)
    nodes = getindex!(cache, cell_nodes, cell)
    for node in nodes
      i += 1
      values[i] = node_value[node]
    end
  end
  values
end

function to_dg_cell_values(grid::Grid, cell_value::Vector)
  cell_nodes = get_cell_node_ids(grid)
  i = 0
  cache = array_cache(cell_nodes)
  for cell in 1:length(cell_nodes)
    nodes = getindex!(cache, cell_nodes, cell)
    for node in nodes
      i += 1
    end
  end
  T = eltype(cell_value)
  values = zeros(T,i)
  i = 0
  for cell in 1:length(cell_nodes)
    nodes = getindex!(cache, cell_nodes, cell)
    for node in nodes
      i += 1
      values[i] = cell_value[cell]
    end
  end
  values
end

# Obtain edge and vertex skeletons:
function to_lowdim_grid(grid::Grid, ::Val{D}) where D
  topo = GridTopology(grid)
  labels = FaceLabeling(topo)
  model = DiscreteModel(grid, topo, labels)
  Grid(ReferenceFE{D}, model)
end
to_lowdim_grid(grid::Grid{D}, ::Val{D}) where D = grid

to_cell_grid(grid::Grid)   = to_lowdim_grid(grid, Val(2))
to_edge_grid(grid::Grid)   = to_lowdim_grid(grid, Val(1))
to_vertex_grid(grid::Grid) = to_lowdim_grid(grid, Val(0))

to_scalar(a) = norm(a)

function to_grid(Ω::Triangulation)
  vds = visualization_data(Ω,"")
  first(vds).grid
end

function to_grid(Ω::Triangulation, uh)
  vds = visualization_data(Ω,"",cellfields=[""=>uh])
  grid = first(vds).grid
  nodaldata = first(first(vds).nodaldata)[2]
  scalarnodaldata = map(to_scalar,nodaldata)
  grid, scalarnodaldata
end

to_scalar(x) = norm(x)

#= Obtain boundary faces:

function to_boundary_grid(grid::Grid)
  Df = 2
  topo = GridTopology(grid)
  labels = FaceLabeling(topo)
  model = DiscreteModel(grid, topo, labels)
  face_grid = Grid(ReferenceFE{Df}, model)
  face_to_mask = get_face_mask(labels, "boundary", Df)
  GridPortion(face_grid, face_to_mask)
end

function to_boundary_grid_with_map(grid::Grid)
  Df = 2
  Dc = 3
  topo = GridTopology(grid)
  labels = FaceLabeling(topo)
  model = DiscreteModel(grid, topo, labels)
  face_grid = Grid(ReferenceFE{Df}, model)
  face_to_mask = get_face_mask(labels, "boundary", Df)
  face_to_cells = get_faces(topo, Df, Dc)
  face_to_cell = lazy_map(first, face_to_cells)
  bface_to_face = findall(face_to_mask)
  bface_to_cell = lazy_map(Reindex(face_to_cell), bface_to_face)
  GridPortion(face_grid, bface_to_face), bface_to_cell
end=#
