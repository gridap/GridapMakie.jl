module TestGridapMakie

using GridapMakie
using CairoMakie
using Test

using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs

import FileIO

model_2D = CartesianDiscreteModel((0.,1.5,0.,1.),(15,10)) |> simplexify
model_3D = CartesianDiscreteModel((0.,1.5,0.,1.,0.,2.),(15,10,10)) |> simplexify
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

function demo(f, suffix::String, grid; colorbar=false)
    println("*"^80)
    filename = "$(suffix).png"
    @show filename
    fig, ax, tp = f(grid)
    if colorbar
        Colorbar(fig[1,2], tp)
    end
    path = joinpath(OUTDIR, filename)
    FileIO.save(path, fig)
    return true
end

@testset "smoketests" begin
    @test demo("mesh_2d", grid_2D) do grid
        mesh(grid, color=:purple)
    end
    @test demo("mesh_2d_colormap&bar", grid_2D; colorbar=true) do grid
        mesh(grid, color=nodaldata_2D; colormap =:heat)
    end
    @test demo("wireframe_2d", grid_2D) do grid
        wireframe(grid; color=:green, linewidth=2.5)
    end
    @test demo("quad_mesh_2d", quad_grid_2D) do grid
        mesh(grid; color=:red)
    end
    @test demo("mesh_3d", grid_3D) do grid
        mesh(grid, color=:purple)
    end
    @test demo("mesh_3d_colormap&bar", grid_3D; colorbar=true) do grid
        mesh(grid, color=nodaldata_3D; colormap =:Spectral)
    end
    @test demo("wireframe_3d", grid_3D) do grid
        wireframe(grid; color=:blue, linewidth=.5)
    end
end

end #module
