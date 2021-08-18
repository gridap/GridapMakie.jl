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
celldata_3D = rand(num_cells(grid_3D))
nodaldata_3D = rand(num_faces(model_3D,0))
quad_nodaldata_3D = rand(num_nodes(quad_grid_3D))
quad_celldata_3D = rand(num_cells(quad_grid_3D))

domain = (0,1,0,1)
cell_nums = (10,10)
model = CartesianDiscreteModel(domain,cell_nums) |> simplexify
Ω = Triangulation(model)
Γ = BoundaryTriangulation(model)
Λ = SkeletonTriangulation(model)
n_Λ = get_normal_vector(Λ)
u(x) = sin(π*(x[1]+x[2]))
uh = CellField(x->sin(π*(x[1]+x[2])),Ω)
#reffe = ReferenceFE(lagrangian,Float64,1)
#V = FESpace(model,reffe)
#uh = interpolate(u,V)
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
        fig = plot(grid_2D,color=:pink)
        wireframe!(grid_2D)
        scatter!(grid_2D)
        fig
    end
    @test savefig("Fig11") do
        fig = plot(Ω, uh)
        plot!(Γ, uh,linewidth=4)
        fig
    end
    @test savefig("Fig12") do
        fig = plot(Ω, color=:green)
        wireframe!(Ω, color=:red, linewidth=2.5)
        fig
    end
    @test savefig("Fig13") do
      fig, _ , plt = plot(Ω, color=3*celldata, colormap=:heat)
        Colorbar(fig[1,2], plt)
        fig
    end
    @test savefig("Fig14") do
      fig,_,plt = plot(Λ, jump(n_Λ⋅∇(uh)),linewidth=4, colorrange=(0,1))
        Colorbar(fig[1,2],plt)
        fig
    end
    @test savefig("fig15") do 
      fig, _ , plt = plot(uh, colormap=:Spectral)#, colorrange=(0,1.))
        Colorbar(fig[1,2], plt)
        fig   
    end
end

end #module
