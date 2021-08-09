# Create recipe: 
@Makie.recipe(Cells) do scene
    Makie.Attributes(;
    
      # Use default theme:
      Makie.default_theme(scene, Makie.Mesh)...,
      Makie.default_theme(scene, Makie.Lines)...,
      Makie.default_theme(scene, Makie.Scatter)...,

      # Custom arguments:
      color      = :pink,
      colormap   = :bluesreds,
      colorrange = nothing,

      # Otherwise, 2D plots don't use custom default colors:
      cycle      = nothing,

      # Force no shading:
      shading    = false
    )
end

# Plot! especialization for Triangulation and CellField types:
function Makie.plot!(plot::Cells{<:Union{Tuple{Triangulation, CellField}, Tuple{Union{Triangulation, CellField}}}})
  grid, color = color_handling(plot)
  cells!(plot, grid; 
  color       = color,              colormap      = plot[:colormap],      colorrange   = plot[:colorrange],
  ambient     = plot[:ambient],     diffuse       = plot[:diffuse],       inspectable  = plot[:inspectable],
  interpolate = plot[:interpolate], lightposition = plot[:lightposition], nan_color    = plot[:nan_color],
  overdraw    = plot[:overdraw],    shading       = plot[:shading],       shininess    = plot[:shininess],
  specular    = plot[:specular],    ssao          = plot[:ssao],          transparency = plot[:transparency], 
  visible     = plot[:visible]
  )
end

# Plot! especialization for Grid:  
function Makie.plot!(plot::Cells{<:Tuple{Grid}})

  grid = plot[1][]
  Dc = num_cell_dims(grid)

  # Dispatch edges according to cell dimension Dc:
  if Dc == 0
    return plot_Ngon_vertices!(plot, grid)
  elseif Dc == 1
    return plot_Ngon_edges!(plot, grid)
  elseif Dc == 2
    return plot_Ngon_cells!(plot, grid)
  end

  return plot_Ngon_cells!(plot, grid |> to_cell_grid)
end

# 2D plots:
function plot_Ngon_cells!(plot::Cells{<:Tuple{Grid}}, grid::Grid)
  grid_, color = color_handling(plot, grid)
  Makie.mesh!(plot, grid_; 
    color       = color,              colormap      = plot[:colormap],      colorrange   = plot[:colorrange],
    ambient     = plot[:ambient],     diffuse       = plot[:diffuse],       inspectable  = plot[:inspectable],
    interpolate = plot[:interpolate], lightposition = plot[:lightposition], nan_color    = plot[:nan_color],
    overdraw    = plot[:overdraw],    shading       = plot[:shading],       shininess    = plot[:shininess],
    specular    = plot[:specular],    ssao          = plot[:ssao],          transparency = plot[:transparency], 
    visible     = plot[:visible]
  )
end

# 1D plots:
function plot_Ngon_edges!(plot::Cells{<:Tuple{Grid}}, grid::Grid)
  grid_, color = color_handling(plot, grid)
  Makie.linesegments!(plot, grid_;
    color     = color,              colormap      = plot[:colormap],      colorrange   = plot[:colorrange],
    ambient   = plot[:ambient],     diffuse       = plot[:diffuse],       inspectable  = plot[:inspectable],
    linewidth = plot[:linewidth],   lightposition = plot[:lightposition], nan_color    = plot[:nan_color],
    overdraw  = plot[:overdraw],    linestyle     = plot[:linestyle],     shininess    = plot[:shininess],
    specular  = plot[:specular],    ssao          = plot[:ssao],          transparency = plot[:transparency], 
    visible   = plot[:visible]
  )
end

# 0D plots:
function plot_Ngon_vertices!(plot::Cells{<:Tuple{Grid}}, grid::Grid)
  grid_, color = color_handling(plot, grid)
  Makie.scatter!(plot, grid_;
    color         = color,                colormap         = plot[:colormap],         colorrange      = plot[:colorrange],
    ambient       = plot[:ambient],       diffuse          = plot[:diffuse],          inspectable     = plot[:inspectable],
    distancefield = plot[:distancefield], glowcolor        = plot[:glowcolor],        glowwidth       = plot[:glowwidth],
    linewidth     = plot[:linewidth],     lightposition    = plot[:lightposition],    nan_color       = plot[:nan_color],
    marker        = plot[:marker],        marker_offset    = plot[:marker_offset],    markersize      = plot[:markersize],
    overdraw      = plot[:overdraw],      makerspace       = plot[:markerspace],      shininess       = plot[:shininess],
    specular      = plot[:specular],      ssao             = plot[:ssao],             transparency    = plot[:transparency], 
    visible       = plot[:visible],       rotations        = plot[:rotations],        strokecolor     = plot[:strokecolor],
    strokewidth   = plot[:strokewidth],   transform_marker = plot[:transform_marker], uv_offset_width = plot[:uv_offset_width]
  )
end

# Handle plot colors:
color_handling(plot::Union{Cells{<:Tuple{Triangulation}}, Edges{<:Tuple{Triangulation}}}) = (to_visualization_Triangulation(plot[1][]), plot[:color])

color_handling(plot::Union{Cells{<:Tuple{CellField}}, Edges{<:Tuple{CellField}}}) = to_visualization_data(plot[1][] |> get_triangulation, plot[1][])

color_handling(plot::Union{Cells{<:Tuple{Triangulation, CellField}}, Edges{<:Tuple{Triangulation, CellField}}}) = to_visualization_data(plot[1][], plot[2][])

function color_handling(plot::Cells{<:Tuple{Grid}}, grid::Grid)
  
  # Retrieve color:
  color = plot[:color][]

  grid_ = to_plot_mesh(grid)
  
  if color isa AbstractVector
    if plot[:colorrange][] === nothing
      plot[:colorrange][] = extrema(color)
    end
    if length(color) != GeometryBasics.coordinates(grid_) |> length
        color = if length(color) == num_nodes(grid)
                  to_dg_node_values(grid, color)
                elseif length(color) == num_cells(grid)
                  to_dg_cell_values(grid, color)
                end
    end
  end

  grid_, color
end