# # Hello
#
import AbstractPlotting # hide
AbstractPlotting.inline!(true) # hide
using Makie
using CairoMakie # hide
plot(randn(10))

# and one more
plot(randn(11))

using Makie
using GridapMakie
using Gridap

# # 1d
lines(GridapMakie.demo_visdata(spacedim=1, valuetype=Float64))
#
lines(GridapMakie.demo_visdata(spacedim=1, valuetype=VectorValue{1, Float64}))

# # 2d
mesh(GridapMakie.demo_visdata(spacedim=2, valuetype=Float64))
#
quiver(GridapMakie.demo_visdata(spacedim=2, valuetype=VectorValue{2, Float64}))
