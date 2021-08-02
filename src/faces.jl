# Create recipe: 
@Makie.recipe(Faces, grid) do scene
    Makie.Attributes(;
    
      # Use default theme:
      Makie.default_theme(scene, Makie.Mesh)...,
      Makie.default_theme(scene, Makie.Lines)...,
      Makie.default_theme(scene, Makie.Scatter)...,

      # Custom arguments:
      color      = :pink,
      colormap   = :bluesreds,
      colorrange = nothing,
      fieldstyle = :nodes,

      # Otherwise, 2D plots don't use custom default colors:
      cycle      = nothing,

      # Force no shading:
      shading    = false
    )
end
  
# Plot! especialization:  
function Makie.plot!(plot::Faces{<:Tuple{Grid}})

  grid = plot[:grid][]
  Dc = num_cell_dims(grid)

  # Dispatch edges according to cell dimension Dc:
  if Dc == 0
    plot_Ngon_vertices!(plot, grid)
  elseif Dc == 1
    plot_Ngon_edges!(plot, grid)
  else
    plot_Ngon_faces!(plot, grid |> to_face_grid)
  end

end

# 2D plots:
function plot_Ngon_faces!(plot::Faces{<:Tuple{Grid}}, grid::Grid)

  # Retrieve plot attributes:
  fieldstyle    = plot[:fieldstyle][]
  color         = plot[:color][]

  grid_ = to_plot_mesh(grid)
  if color isa AbstractVector
    if plot[:colorrange][] === nothing
      plot[:colorrange][] = extrema(color)
    end
    if length(color) != GeometryBasics.coordinates(grid_) |> length
      color = if fieldstyle == :nodes
                to_dg_node_values(grid, color)
              elseif fieldstyle == :cells
                to_dg_cell_values(grid, color)
              else
                error("Invalid fieldstyle")
              end
    end
  end
  Makie.mesh!(plot, grid_; 
    color       = color,                colormap      = plot[:colormap][],      colorrange   = plot[:colorrange][],
    ambient     = plot[:ambient][],     diffuse       = plot[:diffuse][],       inspectable  = plot[:inspectable][],
    interpolate = plot[:interpolate][], lightposition = plot[:lightposition][], nan_color    = plot[:nan_color][],
    overdraw    = plot[:overdraw][],    shading       = plot[:shading][],       shininess    = plot[:shininess][],
    specular    = plot[:specular][],    ssao          = plot[:ssao][],          transparency = plot[:transparency][], 
    visible     = plot[:visible][]
  )
end

# 1D plots:
function plot_Ngon_edges!(plot::Faces{<:Tuple{Grid}}, grid::Grid)

  # Retrieve color attribute:
  color      = plot[:color][]

  if color isa AbstractVector
    if plot[:colorrange][] === nothing
      plot[:colorrange][] = extrema(color)
    end
    color = if length(color) == num_nodes(grid)
              to_dg_node_values(grid, color)
            else 
              to_dg_cell_values(grid, color)
    end
  end
  Makie.linesegments!(plot, grid |> to_plot_mesh;
    color     = color,                colormap      = plot[:colormap][],      colorrange   = plot[:colorrange][],
    ambient   = plot[:ambient][],     diffuse       = plot[:diffuse][],       inspectable  = plot[:inspectable][],
    linewidth = plot[:linewidth][],   lightposition = plot[:lightposition][], nan_color    = plot[:nan_color][],
    overdraw  = plot[:overdraw][],    linestyle     = plot[:linestyle][],     shininess    = plot[:shininess][],
    specular  = plot[:specular][],    ssao          = plot[:ssao][],          transparency = plot[:transparency][], 
    visible   = plot[:visible][]
  )
end

# 0D plots:
function plot_Ngon_vertices!(plot::Faces{<:Tuple{Grid}}, grid::Grid)

  # Retrieve color attribute:
  color      = plot[:color][]

  if color isa AbstractVector
    if plot[:colorrange][] === nothing
      plot[:colorrange][] = extrema(color)
    end
    color = to_dg_node_values(grid, color)
  end
  Makie.scatter!(plot, grid |> to_plot_mesh;
    color         = color,                  colormap         = plot[:colormap][],         colorrange      = plot[:colorrange][],
    ambient       = plot[:ambient][],       diffuse          = plot[:diffuse][],          inspectable     = plot[:inspectable][],
    distancefield = plot[:distancefield][], glowcolor        = plot[:glowcolor][],        glowwidth       = plot[:glowwidth][],
    linewidth     = plot[:linewidth][],     lightposition    = plot[:lightposition][],    nan_color       = plot[:nan_color][],
    marker        = plot[:marker][],        marker_offset    = plot[:marker_offset][],    markersize      = plot[:markersize][],
    overdraw      = plot[:overdraw][],      makerspace       = plot[:markerspace][],      shininess       = plot[:shininess][],
    specular      = plot[:specular][],      ssao             = plot[:ssao][],             transparency    = plot[:transparency][], 
    visible       = plot[:visible][],       rotations        = plot[:rotations][],        strokecolor     = plot[:strokecolor][],
    strokewidth   = plot[:strokewidth][],   transform_marker = plot[:transform_marker][], uv_offset_width = plot[:uv_offset_width][]
  )
end