module TestGridapMakie

using GridapMakie
using CairoMakie
using Test
using GeometryBasics

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
celldata_3D = rand(num_faces(model_3D,2))
nodaldata_3D = rand(num_faces(model_3D,0))
quad_nodaldata_3D = rand(num_nodes(quad_grid_3D))
quad_celldata_3D = rand(num_cells(quad_grid_3D))

domain = (0,1,0,1)
cell_nums = (10,10)
model = CartesianDiscreteModel(domain,cell_nums) |> simplexify
Ω = Triangulation(model)
Γ = BoundaryTriangulation(model)
Λ = SkeletonTriangulation(model)
uh = CellField(x->sin(π*(x[1]+x[2])),Ω)
celldata = rand(num_cells(Ω))

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
        fig = cells(grid_2D, color=GridapMakie.to_dg_mesh(grid_2D)|>GeometryBasics.coordinates|>length|>rand)
        edges!(grid_2D, color=RGBAf0(1,0.2,1,1))
        vertices!(grid_2D, color=2*rand(num_faces(model_2D,0)))
        fig
    end
    @test savefig("Fig2") do
        fig = cells(grid_2D, color=celldata_2D)
        fig
    end
    @test savefig("Fig3") do
        fig, _ , plt = cells(grid_2D, color=nodaldata_2D)
        Colorbar(fig[1,2], plt)
        fig
    end
    @test savefig("Fig4") do
        fig, _ , plt = edges(grid_2D, color=rand(num_faces(model_2D,1)))
        Colorbar(fig[1,2], plt)
        fig
    end
    @test savefig("Fig5") do
        fig, _ , plt = edges(grid_2D, color=nodaldata_2D)
        Colorbar(fig[1,2], plt)
        fig
    end
    @test savefig("Fig6") do
        fig = cells(grid_3D, color=GridapMakie.to_cell_grid(grid_3D)|>GridapMakie.to_dg_mesh|>GeometryBasics.coordinates|>length|>rand)
        edges!(grid_3D)
        vertices!(grid_3D)
        fig
    end
    @test savefig("Fig7") do
        fig = cells(grid_3D, color=celldata_3D)
        fig
    end
    @test savefig("Fig8") do
        fig, _ , plt = cells(grid_3D, color=nodaldata_3D)
        edges!(grid_3D, color=:black)
        Colorbar(fig[1,2], plt)
        fig
    end
    @test savefig("Fig9") do
        fig, _ , plt = edges(grid_3D, color=rand(num_faces(model_3D,1)))
        Colorbar(fig[1,2], plt)
        fig
    end
    @test savefig("Fig10") do
        fig, _ , plt = edges(grid_3D, color=nodaldata_3D, colormap=:Spectral)
        Colorbar(fig[1,2], plt)
        fig
    end
    @test savefig("Fig11") do
        fig = plot(Ω)
        fig
    end
    @test savefig("Fig12") do
        fig = plot(Ω, color=:green)
        edges!(Ω, color=:red, linewidth=2.5)
        fig
    end
    @test savefig("Fig13") do
        fig, _ , plt = plot(Ω, color=celldata, colormap=:heat, colorrange=(0,1))
        Colorbar(fig[1,2], plt)
        fig
    end
    @test savefig("Fig14") do
        fig, ax = plot(Γ, uh, linewidth = 4)
        plot!(Λ, uh,linewidth=5)
        fig
    end
    @test savefig("fig15") do 
        fig, _ , plt = plot(uh, colormap=:heat, colorrange=(0,1.))
        Colorbar(fig[1,2], plt)
        fig   
    end
end

end #module
