# Create recipe: 

@Makie.recipe(Vertices) do scene
    Makie.Attributes(;

      # Use default theme:
      Makie.default_theme(scene, Makie.Scatter)...,

      # Custom arguments:
      color      = :black,
      colormap   = :hawaii,
      colorrange = nothing,

      # Allow to plot custom color:
      cycle      = nothing
    )
end
  
  # Plot! especialization:
  
function Makie.plot!(plot::Vertices{<:Tuple{Grid}})
  grid = plot[1][]
  cells!(plot, grid |> to_vertex_grid;
    color         = plot[:color][],         colormap         = plot[:colormap][],         colorrange      = plot[:colorrange][],
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