
# Create recipe: 

@Makie.recipe(Edges, grid) do scene
  #Makie.default_theme(scene, Makie.LineSegments)
  Makie.Attributes(;
    # generic attributes
    colormap = Makie.theme(scene, :colormap),
    color = Makie.theme(scene, :linecolor),
    linewidth = Makie.theme(scene, :linewidth),

    # new attributes
    fieldstyle = :nodes
  )
end

# Plot! especialization:

function Makie.plot!(plot::Edges{<:Tuple{Grid}})
 
  grid = plot[:grid][]
  color = plot[:color][]
  linewidth = plot[:linewidth][]

  faces!(plot, grid |> to_edge_grid,
    color = color,
    linewidth = linewidth,
    colormap = plot[:colormap]
    )

end