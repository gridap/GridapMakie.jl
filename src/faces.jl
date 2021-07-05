
# Create recipe: 

@Makie.recipe(Faces, grid) do scene
    #Makie.default_theme(scene, Makie.Mesh)
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
  
  function Makie.plot!(plot::Faces{<:Tuple{Grid}})
  
    grid = plot[:grid][]
    color = plot[:color][]
    linewidth = plot[:linewidth][]
  
    Dc = num_cell_dims(grid)
  
    if Dc == 1
      if color isa AbstractVector
        Makie.wireframe!(plot, grid, 
            color = color,
            linewidth = linewidth, 
            colormap = plot[:colormap]
            )
      else
        Makie.wireframe!(plot, grid, 
            color = color,
            linewidth = linewidth,
            colormap = plot[:colormap]
            )
      end
  
    else
      if color isa AbstractVector
        Makie.mesh!(plot, grid, 
          color = color,
          colormap = plot[:colormap]
          )
      else
        Makie.mesh!(plot, grid, 
          color = color,
          colormap = plot[:colormap]
          )
      end
    end
  
  end