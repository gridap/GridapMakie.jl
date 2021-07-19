module TestGridapMakie

using GridapMakie
using CairoMakie
using Test

using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs

import FileIO

model_2D = CartesianDiscreteModel((0.,1.5,0.,1.),(15,10)) |> simplexify
model_3D = CartesianDiscreteModel((0.,1.5,0.,1.,0.,2.),(5,5,5)) |> simplexify
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
        fig = faces(quad_grid_3D)
        fig
    end
    @test savefig("Fig2") do
        fig, ax = faces(quad_grid_3D)
        edges!(ax, quad_grid_3D)
        fig
    end
    @test savefig("Fig3") do
        fig, ax = faces(quad_grid_3D)
        edges!(ax, quad_grid_3D, linewidth=2.5)
        fig
    end
    @test savefig("Fig4") do
        fig, ax = faces(quad_grid_3D, color=:lightseagreen)
        edges!(ax, quad_grid_3D, color=:darkslategray)
        fig
    end
    @test savefig("Fig5") do
        fig = faces(grid_3D, color=celldata_3D, fieldstyle=:cells)
        fig
    end
    @test savefig("Fig6") do
        fig = faces(quad_grid_3D, color=quad_nodaldata_3D, fieldstyle=:nodes)
        fig
    end
    @test savefig("Fig7") do
        fig, ax, plt = faces(quad_grid_3D, color=quad_nodaldata_3D, colorrange=(0,1))
        Colorbar(fig[1,2], plt, ticks=0:0.25:1)
        fig
    end
    @test savefig("Fig8") do
        fig, ax, plt = faces(quad_grid_3D, color=quad_nodaldata_3D, colormap=:heat, colorrange=(0,1))
        Colorbar(fig[1,2], plt, ticks=0:0.25:1)
        fig
    end
    @test savefig("Fig9") do
        fig, ax, plt = edges(quad_grid_3D, color=quad_nodaldata_3D, colorrange=(0,1))
        Colorbar(fig[1,2], plt, ticks=0:0.25:1)
        fig
    end
end

end #module
