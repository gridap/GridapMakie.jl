using GridapMakie
using Test
using Makie
using Gridap
using Gridap.Visualization
import FileIO

const OUTDIR = joinpath(@__DIR__, "output")
rm(OUTDIR, force=true, recursive=true)
mkpath(OUTDIR)

function demo(name;spacedim, valuetype, kw...)
    visdata = GridapMakie.demo_visdata(;spacedim=spacedim, valuetype=valuetype)
    pdeplot = PDEPlot(visdata)
    scene = plot(pdeplot; kw...)
    filename = name*".png"
    path = joinpath(OUTDIR, filename)
    FileIO.save(path, scene)
end
# visdata

demo("1d_Scalar", spacedim=1, valuetype=Float64)
demo("2d_Scalar", spacedim=2, valuetype=Float64)
demo("1d_Vec1d", spacedim=1, valuetype=VectorValue{1,Float64})
demo("1d_Vec2d", spacedim=1, valuetype=VectorValue{2,Float64}, arrowcolor=:blue)
demo("2d_Vec2d", spacedim=2, valuetype=VectorValue{2,Float64}, arrowcolor=:red, arrowsize=0.1)
demo("3d_Vec3d", spacedim=3, valuetype=VectorValue{3,Float64}, arrowsize=0.1)
