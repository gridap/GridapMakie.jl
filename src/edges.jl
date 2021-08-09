# Create recipe: 

@Makie.recipe(Edges) do scene
    Makie.Attributes(;

      # Use default theme:
      Makie.default_theme(scene, Makie.Lines)...,

      # Custom arguments:
      color      = :brown4,
      colormap   = :bluesreds,
      colorrange = nothing,

      # Allow to plot custom color:
      cycle      = nothing
    )
end
  
# Plot! especialization for Grid:  
function Makie.plot!(plot::Edges{<:Tuple{Grid}})
  grid = plot[1][]
  cells!(plot, grid |> to_edge_grid;
    color     = plot[:color][],     colormap      = plot[:colormap],      colorrange   = plot[:colorrange],
    ambient   = plot[:ambient],     diffuse       = plot[:diffuse],       inspectable  = plot[:inspectable],
    linewidth = plot[:linewidth],   lightposition = plot[:lightposition], nan_color    = plot[:nan_color],
    overdraw  = plot[:overdraw],    linestyle     = plot[:linestyle],     shininess    = plot[:shininess],
    specular  = plot[:specular],    ssao          = plot[:ssao],          transparency = plot[:transparency], 
    visible   = plot[:visible]
  )
end

function Makie.plot!(plot::Edges{<:Union{Tuple{Triangulation, CellField}, Tuple{Union{Triangulation, CellField}}}})
  grid, color = color_handling(plot)
  cells!(plot, grid |> to_edge_grid;
    color     = color,     colormap      = plot[:colormap],      colorrange   = plot[:colorrange],
    ambient   = plot[:ambient],     diffuse       = plot[:diffuse],       inspectable  = plot[:inspectable],
    linewidth = plot[:linewidth],   lightposition = plot[:lightposition], nan_color    = plot[:nan_color],
    overdraw  = plot[:overdraw],    linestyle     = plot[:linestyle],     shininess    = plot[:shininess],
    specular  = plot[:specular],    ssao          = plot[:ssao],          transparency = plot[:transparency], 
    visible   = plot[:visible]
  )
end