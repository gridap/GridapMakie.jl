module TestGridapMakie

using GridapMakie
using CairoMakie
using Test

using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs

import FileIO

model = CartesianDiscreteModel((0.,1.5,0.,1.),(15,10)) |> simplexify
grid = get_grid(model)
celldata = rand(num_cells(grid))
nodaldata = rand(num_nodes(grid))

const OUTDIR = joinpath(@__DIR__, "output")
rm(OUTDIR, force=true, recursive=true)
mkpath(OUTDIR)

function demo(verb, suffix::String ; grid, kw...)
    println("*"^80)
    filename = "$(verb)_$(suffix).png"
    scene = verb(grid; kw...)
    path = joinpath(OUTDIR, filename)
    FileIO.save(path, scene)
    return true
end

@testset "smoketests" begin
    @test demo(mesh, "2d", grid=grid)
    @test demo(wireframe, "2d", grid=grid)
end

end #module
