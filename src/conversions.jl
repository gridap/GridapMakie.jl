Makie.convert_arguments(::Type{<:Makie.Mesh}, grid::Grid) = ( grid |> to_plot_mesh, )
Makie.convert_arguments(::Type{<:Makie.Wireframe}, grid::Grid) = ( grid |> to_plot_mesh, )
#Makie.convert_arguments(::Makie.PlotFunc, grid::Grid) = ( grid |> to_plot_mesh, )

function to_plot_mesh(grid::Grid)
  grid |> UnstructuredGrid |> to_plot_mesh
end

function to_plot_mesh(grid::CartesianGrid)
  grid |> simplexify |> to_plot_mesh
end

function to_plot_mesh(grid::UnstructuredGrid)
  if num_cell_dims(grid) == 3
    grid |> to_boundary_grid |> to_simplex_grid |> to_mesh |> GeometryBasics.normal_mesh
  else
    grid |> to_simplex_grid |> to_mesh
  end
end

function to_simplex_grid(grid)
  reffes = get_reffes(grid)
  polys = map(get_polytope,reffes)
  all(is_simplex,polys) ? grid : simplexify(grid)
end

function to_boundary_grid(grid::UnstructuredGrid)
  topo = GridTopology(grid)
  labels = FaceLabeling(topo)
  model = DiscreteModel(grid,topo,labels)
  face_grid = Grid(ReferenceFE{2},model)
  face_to_mask = get_face_mask(labels,"boundary",2)
  GridPortion(face_grid,face_to_mask)
end

function to_mesh(grid::Grid)
  grid |> UnstructuredGrid |> to_mesh
end

function to_mesh(grid::UnstructuredGrid)
  reffes = get_reffes(grid)
  @assert all(reffe->get_order(reffe)==1,reffes)
  @assert all(reffe->is_simplex(get_polytope(reffe)),reffes)
  xs = get_node_coordinates(grid)
  Tp = eltype(eltype(xs))
  Dp = length(eltype(xs))
  ps = collect(reinterpret(GeometryBasics.Point{Dp,Tp},xs))
  cns = get_cell_node_ids(grid)
  Tc = eltype(eltype(cns))
  Dc = num_cell_dims(grid)
  fs = collect(lazy_map(GeometryBasics.NgonFace{Dc+1,Tc},cns))
  GeometryBasics.Mesh(GeometryBasics.connect(ps,fs))
end

function to_edge_grid(grid::UnstructuredGrid)
  topo = GridTopology(grid)
  labels = FaceLabeling(topo)
  model = DiscreteModel(grid,topo,labels)
  Grid(ReferenceFE{1},model)
end

#=function Makie.wireframe(grid::CartesianGrid; kw...)
    ls = GeometryBasics.Point2f0[]
    cns = get_cell_node_ids(grid)
    xs = get_node_coordinates(grid)
    Tp = eltype(eltype(xs))
    D = length(eltype(xs))
    xs = collect(reinterpret(GeometryBasics.Point{D,Tp},xs))
    for quad in cns # Draw segments counter-clockwise starting from bottom-left.
        push!(ls,
            xs[quad[1]], xs[quad[2]],
            xs[quad[2]], xs[quad[4]],
            xs[quad[4]], xs[quad[3]],
            xs[quad[3]], xs[quad[1]],
        )
    end
    Makie.linesegments(ls; kw...)
end=#
