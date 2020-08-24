module GridapMakie
include("visdata.jl")
include("recipes.jl")


################################################################################
##### MultiFieldPlot
################################################################################
# @recipe(MultiFieldPlot, visualization_data) do scene
#     Theme()
# end
#
# function AP.plot!(p::AP.Plot(MultiFieldPlot))
#     visdata = to_value(p[:visualization_data])::VisualizationData
#     @argcheck ismultifield(visdata)
#     for (key, nodelvals) in visdata.nodaldata
#         visdata_key = setproperties(visdata, nodaldata=Dict(key => nodelvals))
#         plot!(p, Attributes(p), visdata_key)
#     end
#     return p
# end


################################################################################
##### Testing
################################################################################
function demo_data_single_field(;spacedim::Integer, valuetype::Type)
    if spacedim == 1 model = simplexify(CartesianDiscreteModel((0,2pi), (20,)))
        i1,i2,i3 = 1,1,1
    elseif spacedim == 2
        model = simplexify(CartesianDiscreteModel((0,2pi, -pi, pi), (10, 20)))
        i1,i2,i3 = 1,2,2
    elseif spacedim == 3
        model = simplexify(CartesianDiscreteModel((0,2pi, -pi, pi, -1, 1),(10, 20, 13)))
        i1,i2,i3 = 1,2,3
    else
        error()
    end

    T = valuetype
    c1,c2,c3 = 0.5.+1.5.*rand(3)
    f = if T <: VectorValue{1}
            f = pt -> T(c1*sin(pt[i1]))
        elseif T <: VectorValue{2}
            f = pt -> T(c1*pt[i2], -c2*pt[i1])
        elseif T <: VectorValue{3}
            f = pt -> T(c1*sin(pt[i1]), c2*cos(pt[i2]) + pt[i3], c3*pt[i3] - pt[2])
        elseif T <: VectorValue
            error()
        elseif T <: TensorValue
            error()
        elseif spacedim == 1
            pt -> T(c1*sin(pt[1]) + c2)
        elseif spacedim == 2
            pt -> T(c1*sin(pt[1]) * cos(pt[2]) + c2)
        elseif spacedim == 3
            pt -> T(c1*sin(pt[1]) * cos(pt[2]) * pt[3] + c2)
        else
            error()
        end
    V = TestFESpace(reffe=:Lagrangian, order=1, valuetype=valuetype, conformity=:H1, model=model)
    u = interpolate(V, f)
    (model=model, u=u, V=V)
end

function demo_data(;spacedim, valuetype)
    if valuetype isa Type
        return demo_data_single_field(;spacedim=spacedim, valuetype=valuetype)
    elseif valuetype == nothing
        data1 = demo_data_single_field(;spacedim=spacedim, valuetype=Float64)
        return setproperties(data1, u=nothing, V=nothing)
    else
        datas = map(valuetype) do VType
            demo_data_single_field(spacedim=spacedim, valuetype=VType)
        end
        model = first(datas).model
        V = MultiFieldFESpace(map(data -> data.V, datas))
        u = interpolate(V, map(data -> data.u, datas))
        return (model=model, u=u, V=V)
    end
end

function demo_visdata(;kw...)
    data = demo_data(;kw...)
    trian = Triangulation(data.model)
    visdata = if data.u === nothing
        to_visualization_data(trian)
    else
        to_visualization_data(data.u, trian)
    end
    return visdata
end

end#module
