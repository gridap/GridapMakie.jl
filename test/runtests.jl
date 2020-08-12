using GridapMakie
using Test
using Makie
using Gridap
using Gridap.Visualization

function demo(;spacedim, valuetype, kw...)
    if spacedim == 1
        model = simplexify(CartesianDiscreteModel((0,2pi), (20,)))
        i1,i2,i3 = 1,1,1
    elseif spacedim == 2
        model = simplexify(CartesianDiscreteModel((0,2pi, -pi, pi),(10, 20)))
        i1,i2,i3 = 1,2,2
    elseif spacedim == 3
        model = simplexify(CartesianDiscreteModel((0,2pi, -pi, pi, -1, 1),(10, 20, 13)))
        i1,i2,i3 = 1,2,3
    else
        error()
    end

    T = valuetype
    f = if T isa VectorValue{1}
            f = pt -> T(sin(pt[i1]))
        elseif T isa VectorValue{2}
            f = pt -> T(sin(pt[i1]), cos(pt[i2]))
        elseif T isa VectorValue{3}
            f = pt -> T(sin(pt[i1]), cos(pt[i2]), pt[i3])
        elseif T isa VectorValue
            error()
        elseif T isa TensorValue
            error()
        elseif spacedim == 1
            pt -> sin(pt[1])
        elseif spacedim == 2
            pt -> sin(pt[1]) * cos(pt[2])
        elseif spacedim == 3
            pt -> sin(pt[1]) * cos(pt[2]) * pt[3]
        else
            error()
        end
    V = TestFESpace(reffe=:Lagrangian, order=1, valuetype=valuetype, conformity=:H1, model=model)
    u = interpolate(V, f)

    trian = Triangulation(model)
    visdata = visualization_data(trian, cellfields=Dict("u" =>u))
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
