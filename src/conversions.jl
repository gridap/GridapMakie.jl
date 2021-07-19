Makie.convert_arguments(::Type{<:Makie.Mesh}, grid::Grid) = ( grid |> to_plot_mesh, )
#Makie.convert_arguments(::Type{<:Makie.Wireframe}, grid::Grid) = ( grid |> to_plot_mesh, )
#Makie.convert_arguments(::Makie.PlotFunc, grid::Grid) = ( grid |> to_plot_mesh, )

function to_plot_mesh(grid::Grid)
  UnstructuredGrid(grid) |> to_plot_mesh
end

function to_plot_mesh(grid::CartesianGrid)
  simplexify(grid) |> to_plot_mesh
end

function dimension_dispatch(grid::Grid)
  if num_cell_dims(grid) == 3
    to_boundary_grid(grid) |> to_simplex_grid
  else
    to_simplex_grid(grid) 
  end
end

function to_plot_mesh(grid::UnstructuredGrid)
  dimension_dispatch(grid) |> to_mesh |> GeometryBasics.normal_mesh
end

function to_simplex_grid(grid)
  reffes = get_reffes(grid)
  polys = map(get_polytope,reffes)
  all(is_simplex,polys) ? grid : simplexify(grid)
end

function to_boundary_grid(grid::Grid)
  topo = GridTopology(grid)
  labels = FaceLabeling(topo)
  model = DiscreteModel(grid,topo,labels)
  face_grid = Grid(ReferenceFE{2},model)
  face_to_mask = get_face_mask(labels,"boundary",2)
  GridPortion(face_grid,face_to_mask)
end

function to_mesh(grid::Grid)
  UnstructuredGrid(grid) |> to_mesh
end

function to_mesh(grid::UnstructuredGrid)
  reffes = get_reffes(grid)
  @assert all(reffe->get_order(reffe)==1,reffes)
  @assert all(reffe->is_simplex(get_polytope(reffe)),reffes)
  ps, cns = get_nodes_and_ids(grid)
  Tc = eltype(cns) |> eltype
  Dc = num_cell_dims(grid)
  fs = lazy_map(GeometryBasics.NgonFace{Dc+1,Tc},cns) |> collect
  GeometryBasics.connect(ps,fs) |> GeometryBasics.Mesh
end

function to_edge_grid(grid::Grid)
  topo = GridTopology(grid)
  labels = FaceLabeling(topo)
  model = DiscreteModel(grid,topo,labels)
  Grid(ReferenceFE{1},model)
end

function get_nodes_and_ids(grid::Grid)
  xs = get_node_coordinates(grid)
  Tp = eltype(xs) |> eltype
  Dp = eltype(xs) |> length
  xs = reinterpret(GeometryBasics.Point{Dp,Tp},xs) |> collect
  cns = get_cell_node_ids(grid)
  return xs, cns
end