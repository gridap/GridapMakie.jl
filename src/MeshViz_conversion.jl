
function Meshes.SimpleMesh(grid::Grid)
    xs = get_node_coordinates(grid)
    Tp = eltype(eltype(xs))
    D = length(eltype(xs))
    ps = collect(reinterpret(Meshes.Point{D,Tp},xs))
    cns = get_cell_node_ids(grid)
    fs = [Meshes.connect(Tuple(c)) for c in cns]
    return Meshes.SimpleMesh(ps, fs)
end

function Meshes.SimpleMesh(grid::CartesianGrid)
    return Meshes.CartesianGrid(grid)
end

function Meshes.CartesianGrid(grid::CartesianGrid)  
    xs = get_node_coordinates(grid)
    dims = size(xs) .-1
    Tp = eltype(eltype(xs))
    D = length(eltype(xs))
    start = reinterpret(Meshes.Point{D,Tp}, [first(xs)])
    finish = reinterpret(Meshes.Point{D,Tp}, [last(xs)])
    return Meshes.CartesianGrid(start[1], finish[1], dims=dims)
end

function Makie.mesh(grid::Grid; kw...)
    grid = Meshes.SimpleMesh(grid)
    MeshViz.viz(grid; kw...)
end