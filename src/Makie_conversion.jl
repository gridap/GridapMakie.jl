
Makie.convert_arguments(::Makie.PlotFunc, grid::Grid) = (GeometryBasics.Mesh(grid), )

function GeometryBasics.Mesh(grid::Grid)
    GeometryBasics.Mesh(UnstructuredGrid(grid))
end

function GeometryBasics.Mesh(grid::CartesianGrid)
    GeometryBasics.Mesh(simplexify(grid))
end

function get_boundary_grid(grid::UnstructuredGrid)
    topo = GridTopology(grid)
    labels = FaceLabeling(topo)
    model = DiscreteModel(grid,topo,labels)
    face_grid = Grid(ReferenceFE{2},model)
    face_to_mask = get_face_mask(labels,"boundary",2)
    return GridPortion(face_grid,face_to_mask) |> simplexify
end

function _simplex_grid_2_mesh(grid)
    reffes = get_reffes(grid)
    @assert all(reffe->get_order(reffe)==1,reffes)
    xs = get_node_coordinates(grid)
    Tp = eltype(eltype(xs))
    Dp = length(eltype(xs))
    ps = collect(reinterpret(GeometryBasics.Point{Dp,Tp},xs))
    cns = get_cell_node_ids(grid)
    Tc = eltype(eltype(cns))
    Dc = num_cell_dims(grid)
    fs = collect(lazy_map(GeometryBasics.NgonFace{Dc+1,Tc},cns))
    return GeometryBasics.Mesh(GeometryBasics.connect(ps,fs)) |> GeometryBasics.normal_mesh
end

function GeometryBasics.Mesh(grid::UnstructuredGrid)
    if num_cell_dims(grid) == 3
        boundary_grid = get_boundary_grid(grid)
        return GeometryBasics.Mesh(boundary_grid) 
    end
    reffes = get_reffes(grid)
    polys = map(get_polytope,reffes)
    _grid = all(is_simplex,polys) ? grid : simplexify(grid)
    return _simplex_grid_2_mesh(_grid)
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