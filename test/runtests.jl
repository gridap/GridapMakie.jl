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

grid_2D = get_grid(model_2D)
grid_3D = get_grid(model_3D)
quad_grid_2D = get_grid(quad_model_2D)

celldata_2D = rand(num_cells(grid_2D))
nodaldata_2D = 10*rand(num_nodes(grid_2D)) .+ 1
quad_nodaldata_2D = 10*rand(num_nodes(grid_2D)) .+ 1
celldata_3D = rand(num_cells(grid_3D))
nodaldata_3D = 10*rand(num_nodes(grid_3D)) .+ 1

const OUTDIR = joinpath(@__DIR__, "output")
rm(OUTDIR, force=true, recursive=true)
mkpath(OUTDIR)

function savefig(f, suffix::String; colorbar=false)
    fig = f()
    println("*"^80)
    filename = "$(suffix).png"
    @show filename
    path = joinpath(OUTDIR, filename)
    FileIO.save(path, fig)
    return true
end

@testset "GridapMakieTests" begin
    @test savefig("mesh_2d") do
        mesh(grid_2D, color=:purple)
    end
    @test savefig("mesh_2d_colormap&bar") do
        fig,_,tp = mesh(grid_2D, color=nodaldata_2D; colormap =:heat)
        Colorbar(fig[1,2], tp)
        fig
    end
    @test savefig("wireframe_2d") do
        fig, = wireframe(grid_2D; color=:green, linewidth=2.5)
        fig
    end
    @test savefig("quad_mesh_2d", ) do
        fig, = mesh(quad_grid_2D; color=:red)
        fig
    end
    @test savefig("mesh_3d") do
        mesh(grid_3D, color=:purple)
    end
    @test savefig("mesh_3d_colormap&bar") do
        fig,_,tp = mesh(grid_3D, color=nodaldata_3D; colormap =:Spectral)
        Colorbar(fig[1,2], tp)
        fig
    end
    @test savefig("wireframe_3d") do
        fig, = wireframe(grid_3D; color=:blue, linewidth=.5)
    end
end

end #module
