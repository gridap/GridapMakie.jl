using AbstractPlotting
const AP = AbstractPlotting
struct MyFunction end
struct MyGrid end

struct MyArgs
    myfunction::MyFunction
    mygrid::MyGrid
end

@recipe(GridapOwned, myargs) do scene
    Theme()
end

function AP.convert_arguments(trait::AbstractPlotting.PointBased, ::MyArgs)
    AP.convert_arguments(trait, randn(10), randn(10))
end
function AP.convert_arguments(A::Type{<:Arrows}, ::MyArgs)
    AP.convert_arguments(A, [randn(10) for _ in 1:6]...)
end

AP.plottype(::MyFunction, ::MyGrid) = GridapOwned
AP.plottype(::MyArgs) = GridapOwned

function AP.convert_arguments(P::Type{<:AP.AbstractPlot}, f::MyFunction, g::MyGrid)
    AP.convert_arguments(P, MyArgs(f,g))
end

function AP.plot!(p::GridapOwned)
    args = to_value(p[:myargs])
    scatter!(p, args)
end

using Makie
f = MyFunction()
g = MyGrid()
myargs = MyArgs(f,g)
scene1 = scatter(myargs)
lines!(myargs)
scene2 = gridapowned(myargs)
scene3 = gridapowned(f,g)
scene4 = plot(myargs)
scene5 = plot(f,g)
scene6 = scatter(f,g)
scene7 = quiver(f,g, arrowsize=5)
display(hbox(scene1, scene2, scene3, scene4, scene5, scene6, scene7))
