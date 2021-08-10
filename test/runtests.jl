module TestGridapMakie

using GridapMakie
using GridapMakie: PlotGrid
#using CairoMakie
using GLMakie
using Test

using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs

import FileIO

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


model = CartesianDiscreteModel((0,1,0,2),(5,5)) |> simplexify

grid = get_grid(model)
#grid = Grid(ReferenceFE{1},model)
#grid = Grid(ReferenceFE{0},model)
celldata = rand(num_cells(grid))
nodaldata = rand(num_nodes(grid))
fig,ax,sc = mesh(PlotGrid(grid),color=nodaldata,shading=false)
wireframe!(PlotGrid(grid),color=:black,linewidth=3)
scatter!(PlotGrid(grid),color=:red)
display(fig)

Ω = Triangulation(model)
Γ = BoundaryTriangulation(model)
fig,ax,sc = plot(Ω,x->x[1]*x[2],shading=false)
wireframe!(Ω,color=:white)
scatter!(Ω,color=:green)
plot!(Γ,x->x[2]+x[1],linewidth=8)
display(fig)


#uh = CellField(x->x[1]*x[2],Ω)
#Λ = SkeletonTriangulation(model)
#fig, = plot(Λ,mean(uh))
#display(fig)



#model_2D = CartesianDiscreteModel((0,1,0,1),(5,5)) |> simplexify

#model_2D = CartesianDiscreteModel((0,1,0,1),(5,5)) |> simplexify
#model_3D = CartesianDiscreteModel((0,1,0,1,0,1),(5,5,5)) |> simplexify
#quad_model_2D = CartesianDiscreteModel((0.,1.5,0.,1.),(15,10))
#quad_model_3D = CartesianDiscreteModel((0.,1.5,0.,1.,0.,2.),(5,5,5))
#
#grid_2D = get_grid(model_2D)
#grid_3D = get_grid(model_3D)
#quad_grid_2D = get_grid(quad_model_2D)
#quad_grid_3D = get_grid(quad_model_3D)
#
#celldata_2D = rand(num_cells(grid_2D))
#nodaldata_2D = rand(num_nodes(grid_2D))
#quad_nodaldata_2D = rand(num_nodes(quad_grid_2D))
#quad_celldata_2D = rand(num_cells(quad_grid_2D))
#celldata_3D = rand(num_faces(model_3D,2))
#nodaldata_3D = rand(num_faces(model_3D,0))
#quad_nodaldata_3D = rand(num_nodes(quad_grid_3D))
#quad_celldata_3D = rand(num_cells(quad_grid_3D))
#
#const OUTDIR = joinpath(@__DIR__, "output")
#rm(OUTDIR, force=true, recursive=true)
#mkpath(OUTDIR)
#
#function savefig(f, suffix::String)
#    fig = f()
#    println("*"^80)
#    filename = "$(suffix).png"
#    @show filename
#    path = joinpath(OUTDIR, filename)
#    FileIO.save(path, fig)
#    return true
#end
#
#@testset "GridapMakieTests" begin
#    @test savefig("Fig1") do
#        fig, ax = faces(grid_2D, color=rand(150))
#        edges!(ax, grid_2D)
#        vertices!(ax, grid_2D, color=:red)
#        fig
#    end
#    @test savefig("Fig2") do
#        fig = faces(grid_2D, color=celldata_2D, fieldstyle=:cells)
#        fig
#    end
#    @test savefig("Fig3") do
#        fig, ax, plt = faces(grid_2D, color=nodaldata_2D, colormap=:heat)
#        edges!(ax, grid_2D, color=:black)
#        fig
#    end
#    @test savefig("Fig4") do
#        fig, ax, plt = faces(grid_2D, color=nodaldata_2D)
#        edges!(grid_2D, color=:black)
#        Colorbar(fig[1,2], plt, ticks=0:0.25:1)
#        fig
#    end
#    @test savefig("Fig5") do
#        fig, ax, plt = edges(grid_2D, color=rand(num_faces(model_2D,1)), colorrange=(0,1), colormap=:Spectral)
#        Colorbar(fig[1,2], plt, ticks=0:0.25:1)
#        fig
#    end
#end

end #module
