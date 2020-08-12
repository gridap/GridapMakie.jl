using GridapMakie
using Test
using Makie
using Gridap
using Gridap.Visualization

function demo(;spacedim, valuetype, kw...)
    visdata = GridapMakie.demo_visdata(;spacedim=spacedim, valuetype=valuetype)
    pdeplot = PDEPlot(visdata)
    plt = plot(pdeplot; kw...)
end
# visdata

demo(spacedim=1, valuetype=Float64)
demo(spacedim=2, valuetype=Float64)
demo(spacedim=1, valuetype=VectorValue{1,Float64})
demo(spacedim=1, valuetype=VectorValue{2,Float64}, arrowcolor=:blue)
demo(spacedim=3, valuetype=VectorValue{3,Float64})
demo(spacedim=2, valuetype=VectorValue{2,Float64}, arrowcolor=:red, arrowsize=0.1)
