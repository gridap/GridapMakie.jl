
# Create recipe: 

@Makie.recipe(Edges, grid) do scene
    Makie.Attributes(;

      # Use default theme:
      Makie.default_theme(scene, Makie.Lines)...,

      # Custom arguments:
      color      = :brown4,
      colormap   = :bluesreds,
      colorrange = nothing,

      # Otherwise, 2D plots don't use custom default colors.
      cycle      = nothing, 
    )
end
  
  # Plot! especialization:
  
function Makie.plot!(plot::Edges{<:Tuple{Grid}})
  
  # Retrieve plot arguments:
  grid      = plot[:grid][]
  color     = plot[:color][]
  linewidth = plot[:linewidth][]
  colormap  = plot[:colormap]

  if color isa AbstractVector
    if plot[:colorrange][] === nothing
      plot[:colorrange][] = extrema(color)
    end
    faces!(plot, grid |> to_edge_grid,
      color      = color,
      linewidth  = linewidth,
      colormap   = colormap,
      colorrange = plot[:colorrange][]
      )
  else 
    faces!(plot, grid |> to_edge_grid,
      color     = color,
      linewidth = linewidth
      )
  end
end