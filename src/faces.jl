# Create recipe: 
@Makie.recipe(Faces, grid) do scene
    Makie.Attributes(;
    
      # Use default theme:
      Makie.default_theme(scene, Makie.Mesh)...,

      # Custom arguments:
      color      = :darkmagenta,
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
    plot[:colorrange][] = extrema(color)
    if fieldstyle == :nodes
      Makie.mesh!(plot, grid, 
        color    = color,
        colormap = colormap
        )
    elseif fieldstyle == :cells
      _grid = to_mesh(grid)
      cmap = Makie.interpolated_getindex.(
              Ref(Makie.to_colormap(colormap, length(_grid))),
              Float64.(color),
              Ref(plot[:colorrange][])
              )
      for (ctr, face) in enumerate(_grid)
        Makie.mesh!(plot, face,
          colormap   = colormap,
          color      = cmap[ctr]
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
  xs = get_node_coordinates(grid)
  Tp = eltype(xs) |> eltype
  Dp = eltype(xs) |> length
  xs = reinterpret(GeometryBasics.Point{Dp,Tp},xs) |> collect
  cns = get_cell_node_ids(grid)
  ls = GeometryBasics.Point{Dp,Tp}[]

  if color isa AbstractVector
    plot[:colorrange][] = extrema(color)
    colortype = eltype(color)
    colors = colortype[]

    # Draw every segment and assign a color separately:
    for edge in cns 
      push!(ls,
          xs[edge[1]], xs[edge[2]]
      )
      push!(colors,
          color[edge[1]], color[edge[2]]
      )
    end

  # Single color:
  else
    colors = color
    for edge in cns
      push!(ls,
          xs[edge[1]], xs[edge[2]]
      )
    end
  end

  Makie.linesegments!(plot, ls, color=colors, linewidth=linewidth, colormap=colormap)
end