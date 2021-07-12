
# Create recipe: 

@Makie.recipe(Edges, grid) do scene
    Makie.Attributes(;
      Makie.default_theme(scene, Makie.Lines)...,
      color = :khaki,
      cycle = nothing
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
    plot[:colorrange][] = extrema(color)
    faces!(plot, grid |> to_edge_grid,
      color     = color,
      linewidth = linewidth,
      colormap  = colormap
      )
  else 
    faces!(plot, grid |> to_edge_grid,
      color     = color,
      linewidth = linewidth
      )
  end
end