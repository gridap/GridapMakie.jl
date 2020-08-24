module TestGridapMakie

using GridapMakie
using Test
using Makie
using Gridap
using Gridap.Visualization
import AbstractPlotting; const AP = AbstractPlotting
import FileIO

const OUTDIR = joinpath(@__DIR__, "output")
rm(OUTDIR, force=true, recursive=true)
mkpath(OUTDIR)

function demo(verb, suffix::String ;spacedim, valuetype, kw...)
    println("*"^80)
    filename = "$(verb)_$(suffix).png"
    @show filename
    @show verb
    data = GridapMakie.demo_data(spacedim=spacedim, valuetype=valuetype)
    args = if data.u !== nothing
        (data.model, data.u)
    else
        (data.model, )
    end
    @show typeof(args)
    @show AP.plottype(args...)
    scene = verb(args...; kw...)
    path = joinpath(OUTDIR, filename)
    FileIO.save(path, scene)
    return true
end
# visdata

@testset "smoketests" begin
    @test demo(wireframe, "2d", spacedim=2, valuetype=nothing)
    @test demo(wireframe, "2d_Scalar", spacedim=2, valuetype=Float64)
    @test demo(plot, "2d", spacedim=2, valuetype=nothing)
    @test demo(plot, "1d_Scalar", spacedim=1, valuetype=Float64)
    @test demo(lines, "1d_Scalar", spacedim=1, valuetype=Float64)
    @test demo(scatter, "1d_Scalar", spacedim=1, valuetype=Float64)
    @test demo(plot, "1d_Vec1d", spacedim=1, valuetype=VectorValue{1,Float64})
    @test demo(lines, "1d_Vec1d", spacedim=1, valuetype=VectorValue{1,Float64})
    @test demo(plot, "2d_Scalar", spacedim=2, valuetype=Float64)
    @test demo(plot, "2d_Vec2d", spacedim=2, valuetype=VectorValue{2,Float64}, arrowcolor=:red, arrowsize=0.1)
    @test demo(plot, "3d_Vec3d", spacedim=3, valuetype=VectorValue{3,Float64}, arrowsize=0.1)
    @test demo(quiver, "3d_Vec3d", spacedim=3, valuetype=VectorValue{3,Float64}, arrowsize=0.1)
    @test_broken demo(plot, "1d_Vec2d", spacedim=1, valuetype=VectorValue{2,Float64}, arrowcolor=:blue)
    @test_broken demo(plot, "1d_Scalar_Scalar", spacedim=1, valuetype=[Float64, Float64])
    @test_broken demo(quiver, "1d_Vec1d", spacedim=1, valuetype=VectorValue{1,Float64})
end

end#module
