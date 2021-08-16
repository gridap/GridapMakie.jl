struct PlotGrid{G<:Grid}
    grid::G
end

Gridap.Geometry.get_grid(pg::PlotGrid) = pg.grid

setup_color(color::Union{Symbol, Makie.Colorant}, ::Grid) = color

function setup_color(color::AbstractArray, grid::Grid)
    color = if length(color) == num_nodes(grid)
                to_dg_node_values(grid, color)
            elseif length(color) == num_cells(grid)
                to_dg_cell_values(grid, color)
            else
                @unreachable
            end
end

function Makie.plot!(plot::Makie.Mesh{<:Tuple{PlotGrid}})
    grid = Makie.lift(get_grid, plot[1])
    color = Makie.lift(setup_color, plot[:color], grid)
    D = num_cell_dims(grid[])

    if D in (2,3)
        mesh = Makie.lift(g->g|>to_face_grid|>to_plot_dg_mesh, grid)
        Makie.mesh!(plot, mesh;
            plot.attributes.attributes..., color = color
        )
    elseif D == 1
        mesh = Makie.lift(to_plot_dg_mesh, grid)
        Makie.linesegments!(plot, mesh;
            plot.attributes.attributes..., color = color
        )
    elseif D == 0
        mesh = Makie.lift(to_plot_dg_mesh, grid)
        Makie.scatter!(plot, mesh;
            plot.attributes.attributes..., color = color
        )
    else
        @unreachable
    end
end

function Makie.convert_arguments(::Type{<:Makie.Wireframe}, pg::PlotGrid)
    grid = get_grid(pg)
    mesh = to_plot_mesh(grid)
    (mesh, )
end

function Makie.convert_arguments(::Type{<:Makie.Scatter}, pg::PlotGrid)
    grid = get_grid(pg)
    node_coords = get_node_coordinates(grid)
    x = map(to_point, node_coords)
    (x, )
end

function Makie.convert_arguments(::Type{<:Makie.Mesh}, trian::Triangulation)
    grid = to_grid(trian)
    (PlotGrid(grid), )
end

function Makie.convert_arguments(t::Type{<:Union{Makie.Wireframe, Makie.Scatter}}, trian::Triangulation)
    grid = to_grid(trian)
    Makie.convert_arguments(t, PlotGrid(grid))
end

Makie.plottype(::Triangulation) = Makie.Mesh

# Meshfield recipe:

@Makie.recipe(MeshField) do scene
    merge!(
        mesh_theme,
        Makie.default_theme(scene, Makie.Mesh)
    )
end

function Makie.plot!(p::MeshField{<:Tuple{Triangulation, Any}})
    trian, uh = p[1:2]
    grid_and_data = Makie.lift(to_grid, trian, uh)
    pg = Makie.lift(i->PlotGrid(i[1]), grid_and_data)
    scalarnodaldata = Makie.lift(i->i[2], grid_and_data)
    
    Makie.mesh!(p, pg;
        p.attributes.attributes..., color = scalarnodaldata
    )
end

Makie.plottype(::Triangulation, ::Any) = MeshField

function Makie.plot!(p::MeshField{<:Tuple{CellField}})
    uh = p[1]
    trian = Makie.lift(get_triangulation, uh)
    grid_and_data = Makie.lift(to_grid, trian, uh)
    pg = Makie.lift(i->PlotGrid(i[1]), grid_and_data)
    scalarnodaldata = Makie.lift(i->i[2], grid_and_data)
    
    Makie.mesh!(p, pg;
        p.attributes.attributes..., color = scalarnodaldata
    )
end

Makie.plottype(::CellField) = MeshField

with_theme(mesh_theme) do
    mesh(grid_2D)
end