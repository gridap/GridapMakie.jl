# Create recipe: 

@Makie.recipe(Edges, grid) do scene
    Makie.Attributes(;

      # Use default theme:
      Makie.default_theme(scene, Makie.Lines)...,

      # Custom arguments:
      color      = :brown4,
      colormap   = :bluesreds,
      colorrange = nothing
    )
end
  
  # Plot! especialization:
  
function Makie.plot!(plot::Edges{<:Tuple{Grid}})
  
  # Retrieve plot arguments:
  grid      = plot[:grid][]
  color     = plot[:color][]

  if color isa AbstractVector
    if plot[:colorrange][] === nothing
      plot[:colorrange][] = extrema(color)
    end
  end

  faces!(plot, grid |> to_edge_grid;
    color     = color,                colormap      = plot[:colormap][],      colorrange   = plot[:colorrange][],
    ambient   = plot[:ambient][],     diffuse       = plot[:diffuse][],       inspectable  = plot[:inspectable][],
    linewidth = plot[:linewidth][],   lightposition = plot[:lightposition][], nan_color    = plot[:nan_color][],
    overdraw  = plot[:overdraw][],    linestyle     = plot[:linestyle][],     shininess    = plot[:shininess][],
    specular  = plot[:specular][],    ssao          = plot[:ssao][],          transparency = plot[:transparency][], 
    visible   = plot[:visible][]
  )
end