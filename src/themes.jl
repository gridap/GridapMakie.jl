# Default themes for GridapMakie:

mesh_theme = Makie.Theme(
    color      = :pink,
    colormap   = :bluesreds,
    shading    = false,
    cycle      = nothing
)

#=mesh_theme = Dict{Symbol, Makie.Observable}(
    :color => :pink,
    :colormap => :bluesreds,
    :shading => false,
    :cycle => nothing 
)=#

wireframe_theme = Makie.Theme(
    color      = :brown4,
    colormap   = :bluesreds,
    cycle      = nothing
)

scatter_theme = Makie.Theme(
    color      = :black,
    colormap   = :hawaii,
    cycle      = nothing
)