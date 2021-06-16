module TestGridapMakie

using GridapMakie
using CairoMakie
using Test

using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs

import FileIO

model = CartesianDiscreteModel((0.,1.5,0.,1.),(15,10)) |> simplexify
quad_model = CartesianDiscreteModel((0.,1.5,0.,1.),(15,10))

grid = get_grid(model)
quad_grid = get_grid(quad_model)

celldata = rand(num_cells(quad_grid))
nodaldata = rand(num_nodes(quad_grid))

const OUTDIR = joinpath(@__DIR__, "output")
rm(OUTDIR, force=true, recursive=true)
mkpath(OUTDIR)

function demo(verb, suffix::String, grid; colorbar = false, kw...)
    println("*"^80)
    filename = "$(verb)_$(suffix).png"
    @show filename
    @show verb
    fig, ax, tp = verb(grid; kw...)
    if colorbar
        Colorbar(fig[1,2], tp)
    end
    path = joinpath(OUTDIR, filename)
    FileIO.save(path, fig)
    return true
end

@testset "smoketests" begin
    @test demo(mesh, "2d", grid; color=:purple)
    @test demo(mesh, "2d_nodal", grid, color=nodaldata)
    @test demo(mesh, "2d_nodal_colormap&bar", grid, color=nodaldata; colorbar=true, colormap =:heat)
    @test demo(wireframe, "2d", grid; color=:green, linewidth=5)
    #@test demo(mesh, "2d_MeshViz_edges", grid)
    #@test demo(mesh, "2d_MeshViz_nodal", grid; facetcolor=nodaldata)
    @test demo(mesh, "2d_quad", quad_grid; color=:red)
    #@test demo(mesh, "2d_quad_MeshViz", quad_grid; elementcolor=celldata, colorbar=true)
    #@test demo(mesh, "2d_quad_MeshViz_2", quad_grid; facetcolor=:blue, showfacets=true)
    @test demo(wireframe, "2d_quad", quad_grid; color=:black, linewidth=2)
end

end #module
