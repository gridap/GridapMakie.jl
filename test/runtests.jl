module TestGridapMakie

using GridapMakie
using Test
using CairoMakie
using Gridap
using Gridap.Visualization
import AbstractPlotting; const AP = AbstractPlotting
import FileIO

const OUTDIR = joinpath(@__DIR__, "output")
rm(OUTDIR, force=true, recursive=true)
mkpath(OUTDIR)

function demo(verb, suffix::String ;spacedim, valuetype, kw...)
    println("*"^80)
    visdata = GridapMakie.demo_visdata(;spacedim=spacedim, valuetype=valuetype)
    filename = "$(verb)_$(suffix).png"
    @show filename
    @show verb
    verb(visdata; kw...)

    data = GridapMakie.demo_data(;spacedim=spacedim, valuetype=valuetype)
    args = if data.u !== nothing
        (data.u, data.model)
    else
        (data.model, )
    end
    @show typeof(args)
    scene = verb(args...; kw...)
    path = joinpath(OUTDIR, filename)
    FileIO.save(path, scene)
    return true
end

@testset "smoketests" begin
    @test demo(mesh, "2d", spacedim=2, valuetype=nothing)
    #@test demo(wireframe, "2d", spacedim=2, valuetype=Float64)
end

end#module
