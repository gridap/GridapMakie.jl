
Makie.convert_arguments(::Makie.PlotFunc, grid::Grid) = (GeometryBasics.Mesh(grid), )

function GeometryBasics.Mesh(grid::Grid)
    GeometryBasics.Mesh(UnstructuredGrid(grid))
end

function GeometryBasics.Mesh(grid::CartesianGrid)
    GeometryBasics.Mesh(simplexify(grid))
end

function GeometryBasics.Mesh(grid::UnstructuredGrid)
    function _simplex_grid_2_mesh(grid)
        reffes = get_reffes(grid)
        @assert all(reffe->get_order(reffe)==1,reffes)
        xs = get_node_coordinates(grid)
        Tp = eltype(eltype(xs))
        D = length(eltype(xs))
        ps = collect(reinterpret(GeometryBasics.Point{D,Tp},xs))
        cns = get_cell_node_ids(grid)
        Tf = eltype(eltype(cns))
        fs = collect(lazy_map(GeometryBasics.SimplexFace{D+1,Tf},cns))
        m = if eltype(fs) <: GeometryBasics.Triangle{}
                GeometryBasics.Mesh(GeometryBasics.connect(ps,fs)) 
            else
                GeometryBasics.Mesh(GeometryBasics.connect(ps,fs)) |> GeometryBasics.normal_mesh
            end
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