# Create recipe: 

@Makie.recipe(Vertices, grid) do scene
    Makie.Attributes(;

      # Use default theme:
      Makie.default_theme(scene, Makie.Scatter)...,

      # Custom arguments:
      color      = :black,
      colormap   = :hawaii,
      colorrange = nothing 
    )
end
  
  # Plot! especialization:
  
function Makie.plot!(plot::Vertices{<:Tuple{Grid}})
  
  # Retrieve plot arguments:
  grid      = plot[:grid][]
  color     = plot[:color][]

  if color isa AbstractVector
    if plot[:colorrange][] === nothing
      plot[:colorrange][] = extrema(color)
    end
  end
  
  faces!(plot, grid |> to_vertex_grid;
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