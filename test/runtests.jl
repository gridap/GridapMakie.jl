module TestGridapMakie

using GridapMakie
using Test
using Makie
using Gridap
using Gridap.Visualization
import FileIO

const OUTDIR = joinpath(@__DIR__, "output")
rm(OUTDIR, force=true, recursive=true)
mkpath(OUTDIR)

function demo(verb, suffix::String ;spacedim, valuetype, kw...)
    visdata = GridapMakie.demo_visdata(;spacedim=spacedim, valuetype=valuetype)
    scene = verb(visdata; kw...)

    filename = "$(verb)_$(suffix).png"
    path = joinpath(OUTDIR, filename)
    FileIO.save(path, scene)
    # also try vanilla plot
    data = GridapMakie.demo_data(spacedim=spacedim, valuetype=valuetype)
    if data.u !== nothing
        pdeplot(data.u, Triangulation(data.model))
        plot(data.u, data.model)
    else
        pdeplot(Triangulation(data.model))
        plot(data.model)
    end
end
# visdata

demo(plot, "2d", spacedim=2, valuetype=nothing)
demo(plot, "1d_Scalar_Scalar", spacedim=1, valuetype=[Float64, Float64])
demo(plot, "1d_Scalar", spacedim=1, valuetype=Float64)
demo(plot, "2d_Scalar", spacedim=2, valuetype=Float64)
demo(plot, "1d_Vec1d", spacedim=1, valuetype=VectorValue{1,Float64})
demo(plot, "1d_Vec2d", spacedim=1, valuetype=VectorValue{2,Float64}, arrowcolor=:blue)
demo(plot, "2d_Vec2d", spacedim=2, valuetype=VectorValue{2,Float64}, arrowcolor=:red, arrowsize=0.1)
demo(plot, "3d_Vec3d", spacedim=3, valuetype=VectorValue{3,Float64}, arrowsize=0.1)

end#module
