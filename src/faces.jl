# Create recipe: 
@Makie.recipe(Faces, grid) do scene
    Makie.Attributes(;
    
      # Use default theme:
      Makie.default_theme(scene, Makie.Mesh)...,

      # Custom arguments:
      color      = :pink,
      colormap   = :bluesreds,
      colorrange = nothing,

      # Otherwise, 2D plots don't use custom default colors.
      cycle      = nothing,
      fieldstyle = :nodes
    )
end
  
# Plot! especialization:  
function Makie.plot!(plot::Faces{<:Tuple{Grid}})

  grid = plot[:grid][]
  Dc = num_cell_dims(grid)

  # Dispatch edges according to cell dimension Dc:
  if Dc == 1
    plot_Ngon_edges!(plot, grid)
  else
    plot_Ngon_faces!(plot, grid)
  end

end

# Mesh and Heatmap for Ngons:
function plot_Ngon_faces!(plot::Faces{<:Tuple{Grid}}, grid::Grid)

  # Retrieve plot attributes:
  fieldstyle = plot[:fieldstyle][]
  color      = plot[:color][]
  colormap   = plot[:colormap][]

  # Represent a field:
  if color isa AbstractVector
    if plot[:colorrange][] === nothing
      plot[:colorrange][] = extrema(color)
    end

    # Nodal field:
    if fieldstyle == :nodes
      Makie.mesh!(plot, grid, 
        color      = color,
        colormap   = colormap,
        colorrange = plot[:colorrange][]
        )

    # Cell field:
    elseif fieldstyle == :cells
      _grid = dimension_dispatch(grid)
      xs, cns = get_nodes_and_ids(_grid)

      # Create colormap from color:
      cmap = Makie.interpolated_getindex.(
              Ref(Makie.to_colormap(colormap, num_cells(_grid))),
              Float64.(color),
              Ref(plot[:colorrange][])
              )
      for (ctr,face) in enumerate(cns)
        Makie.mesh!(plot, xs[face],
          color      = cmap[ctr],
          colormap   = colormap,
          colorrange = plot[:colorrange][]
          )
      end
    else
      error("Invalid field to plot")
    end
  
  # Plot the mesh with a single color:
  else
    Makie.mesh!(plot, grid, 
      color = color
      )
  end

end

# Wireframe for Ngons:
function plot_Ngon_edges!(plot::Faces{<:Tuple{Grid}}, grid::Grid)

  # Retrieve plot attributes:
  linewidth  = plot[:linewidth][]
  color      = plot[:color][]
  colormap   = plot[:colormap][]

  # Grid transformation:
  xs, cns = get_nodes_and_ids(grid)
  ls = GeometryBasics.Point{eltype(xs) |> length, 
                            eltype(xs) |> eltype}[]

  # Color attributes:
  colortype = eltype(color)
  colors = colortype[]

  if color isa AbstractVector
    if plot[:colorrange][] === nothing
      plot[:colorrange][] = extrema(color)
    end
    # Draw every segment and assign a color separately:
    for edge in cns 
      push!(ls,
          xs[edge[1]], xs[edge[2]]
      )
      push!(colors,
          color[edge[1]], color[edge[2]]
      )
    end

  else 
    # Single color:

    for edge in cns
      push!(ls,
          xs[edge[1]], xs[edge[2]]
      )

      #Concatenate colors to avoid empty corners:
      push!(colors,
          color, color
      )
    end
  end

  Makie.lines!(plot, ls, 
    color      = colors, 
    linewidth  = linewidth, 
    colormap   = colormap, 
    colorrange = plot[:colorrange][]
    )
end