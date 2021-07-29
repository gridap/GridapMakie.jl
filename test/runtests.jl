module TestGridapMakie

using GridapMakie
using CairoMakie
using Test

using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs

import FileIO

model_2D = CartesianDiscreteModel((0,1,0,1),(5,5)) |> simplexify
model_3D = CartesianDiscreteModel((0,1,0,1,0,1),(2,2,2)) |> simplexify
quad_model_2D = CartesianDiscreteModel((0.,1.5,0.,1.),(15,10))
quad_model_3D = CartesianDiscreteModel((0.,1.5,0.,1.,0.,2.),(5,5,5))

grid_2D = get_grid(model_2D)
grid_3D = get_grid(model_3D)
quad_grid_2D = get_grid(quad_model_2D)
quad_grid_3D = get_grid(quad_model_3D)

celldata_2D = rand(num_cells(grid_2D))
nodaldata_2D = rand(num_nodes(grid_2D))
quad_nodaldata_2D = rand(num_nodes(quad_grid_2D))
quad_celldata_2D = rand(num_cells(quad_grid_2D))
celldata_3D = rand(num_cells(grid_3D))
nodaldata_3D = rand(num_nodes(grid_3D))
quad_nodaldata_3D = rand(num_nodes(quad_grid_3D))
quad_celldata_3D = rand(num_cells(quad_grid_3D))

const OUTDIR = joinpath(@__DIR__, "output")
rm(OUTDIR, force=true, recursive=true)
mkpath(OUTDIR)

function savefig(f, suffix::String)
    fig = f()
    println("*"^80)
    filename = "$(suffix).png"
    @show filename
    path = joinpath(OUTDIR, filename)
    FileIO.save(path, fig)
    return true
end

@testset "GridapMakieTests" begin
    @test savefig("Fig1") do
        fig, ax = faces(grid_3D, color=:lightseagreen)
        edges!(ax, grid_3D)
        vertices!(ax, grid_3D, color=:red)
        fig
    end
    @test savefig("Fig2") do
        fig = faces(grid_3D, color=celldata_3D, fieldstyle=:cells)
        fig
    end
    @test savefig("Fig3") do
        fig, ax, plt = faces(grid_2D, color=nodaldata_2D, colormap=:heat, colorrange=(0,1), shading=true)
        edges!(ax, grid_2D, color=:black)
        Colorbar(fig[1,2], plt, ticks=0:0.25:1)
        fig
    end
    @test savefig("Fig4") do
        fig, ax, plt = edges(grid_3D, color=nodaldata_3D, colorrange=(0,1))
        Colorbar(fig[1,2], plt, ticks=0:0.25:1)
        fig
    end
    @test savefig("Fig5") do
        fig, ax, plt = edges(grid_3D, color=rand(num_faces(model_3D,1)), colorrange=(0,1), colormap=:Spectral)
        Colorbar(fig[1,2], plt, ticks=0:0.25:1)
        fig
    end
end

end #module
