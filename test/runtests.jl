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

celldata = rand(num_cells(grid))
nodaldata = rand(num_nodes(grid))

const OUTDIR = joinpath(@__DIR__, "output")
rm(OUTDIR, force=true, recursive=true)
mkpath(OUTDIR)

function demo(verb, suffix::String, grid; colorbar =:off, kw...)
    println("*"^80)
    filename = "$(verb)_$(suffix).png"
    @show filename
    @show verb
    fig, ax, tp = verb(grid; kw...)
    if colorbar == :on
        Colorbar(fig[1,2], tp)
    end
    path = joinpath(OUTDIR, filename)
    FileIO.save(path, fig)
    return true
end

@testset "smoketests" begin
    @test demo(mesh, "2d", grid; color=:purple)
    @test demo(mesh, "2d_nodal", grid, color=nodaldata)
    @test demo(mesh, "2d_nodal_colormap&bar", grid, color=nodaldata; colorbar=:on, colormap =:heat)
    @test demo(wireframe, "2d", grid; color=:green, linewidth=2)
    @test demo(mesh, "2d_quad", quad_grid; color=:red)
    @test demo(wireframe, "2d_quad", quad_grid; color=:black, linewidth=2)
end

end #module
