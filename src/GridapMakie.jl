module GridapMakie

export PDEPlot

using Gridap
using AbstractPlotting
using AbstractPlotting: Plot

using Gridap.Visualization: VisualizationData, Visualization
using Gridap.ReferenceFEs
using Gridap.Geometry
using Gridap

################################################################################
##### Dispatch Pipeline
################################################################################

"""
    PDEPlot

The job of `PDEPlot` is to choose a sane visualization of Gridap function like objects.
E.g. produce `Arrows` for a vector field and lines for a scalar field in one space dimension etc.
"""
@recipe(PDEPlot, visualization_data) do scene
    Theme()
end
AbstractPlotting.plottype(::VisualizationData) = PDEPlot

function AbstractPlotting.convert_arguments(P::Type{<:Lines}, visdata::VisualizationData)
    _convert_arguments_for_lines(P, visdata, get_nodalvalues(visdata))
end
function AbstractPlotting.convert_arguments(P::Type{<:Arrows}, visdata::VisualizationData)
    _convert_arguments_for_quiver(P, visdata, get_nodalvalues(visdata))
end
function AbstractPlotting.convert_arguments(P::Type{<:Mesh}, visdata::VisualizationData)
    _convert_arguments_for_mesh(P, visdata, get_nodalvalues(visdata))
end

function AbstractPlotting.convert_arguments(::Type{<:PDEPlot}, fun::SingleFieldFEFunction, grid::Triangulation)
    to_visualzation_data(fun, grid)
    return convert_arguments(PDEPlot, visdata)
end


function AbstractPlotting.plot!(p::PDEPlot{<:Tuple{VisualizationData}})
    visdata = to_value(p[:visualization_data])::VisualizationData
    valuetype = get_valuetype(visdata)
    spacedim = Val(get_spacedim(visdata))
    kw = p.attributes
    _plot_dispatch_spacedim_valuetype(p, visdata, spacedim, valuetype; kw...)
end
function _plot_dispatch_spacedim_valuetype(
    p,
    visdata,
    spacedim::Val{1},
    valuetype::Type{<:VectorValue{1}};
    kw...)
    lines!(p, visdata; kw...)
end
function _plot_dispatch_spacedim_valuetype(p, visdata, spacedim, valuetype; kw...)
    _plot_dispatch_valuetype(p, visdata, valuetype; kw...)
end

function _plot_dispatch_valuetype(p, visdata, valuetype::Type{<:Union{VectorValue, TensorValue}}; kw...)
    quiver!(p,visdata; kw...)
end

function _plot_dispatch_valuetype(p, visdata, valuetype; kw...)
    spacedim = Val(get_spacedim(visdata))
    _plot_dispatch_spacedim(p, visdata, spacedim; kw...)
end

function _plot_dispatch_spacedim(p, visdata, spacedim::Val{1}; kw...)
    lines!(p, visdata; kw...)
end

function _plot_dispatch_spacedim(p, visdata, spacedim::Val{2};
        color=get_nodalvalues(visdata),
        kw...)
    mesh!(p, visdata; color=color, kw...)
    # wireframe!(p, visdata)
end

################################################################################
##### Arrows
################################################################################

function to_makie_matrix(T, itr)
    x1 = first(itr)
    out = Matrix{T}(undef, length(itr), length(x1))
    for i in 1:length(itr)
        for j in 1:length(x1)
            out[i, j] = itr[i][j]
        end
    end
    out
end

function _unzip(itr)
    dim = length(first(itr))
    if dim == 1
        (map(n -> n[1], itr), )
    elseif dim == 2
        (map(n -> n[1], itr), map(n -> n[2], itr))
    elseif dim == 3
        (map(n -> n[1], itr), map(n -> n[2], itr), map(n -> n[3], itr))
    else
        error()
    end
end

function _convert_arguments_for_quiver(P, visdata, nodalvalues)
    spacedim = num_dims(visdata.grid)
    if !(spacedim in 1:3)
        throw(ArgumentError("Plotting of field over $spacedim dimensional space unsupported."))
    end
    n1 = first(nodalvalues)
    @assert n1 isa VectorValue
    vecdim = length(n1)
    if !(vecdim in 1:3)
        throw(ArgumentError("Plotting of field with $vecdim components unsupported."))
    end
    uvw = _unzip(nodalvalues)
    xyz = _unzip(get_node_coordinates(visdata.grid))
    # padding
    while length(uvw) < length(xyz)
        uv = uvw
        w = zero(first(uv))
        uvw = (uv..., w)
    end
    while length(uvw) > length(xyz)
        xy = xyz
        z = zero(first(xy))
        xyz = (xy..., z)
    end
    convert_arguments(P, xyz..., uvw...)
end

################################################################################
##### Lines
################################################################################
single(x) = x
function single(x::Union{VectorValue, TensorValue})
    @assert length(x) == 1
    x[1]
end

function _convert_arguments_for_lines(P, visdata, nodalvalues)
    x = map(pt -> pt[1], get_node_coordinates(visdata.grid))
    y = single.(nodalvalues)
    convert_arguments(P, x, y)
end

################################################################################
##### Mesh
################################################################################
function _convert_arguments_for_mesh(P, visdata, nodalvalues)
    makie_coords_spatial = to_makie_matrix(Float64, get_node_coordinates(visdata.grid))
    makie_conn = to_makie_matrix(Int, get_cell_nodes(visdata.grid))
    makie_coords = hcat(makie_coords_spatial, nodalvalues)
    convert_arguments(P, makie_coords, makie_conn) # color
    # mesh!(p, makie_coords, makie_conn, color = nodalvalues, shading = false)
    # wireframe!(p.plots[end][1], color = (:black, 0.6), linewidth = 3)
end

################################################################################
##### Testing
################################################################################
function demo_model_u(;spacedim, valuetype)
    if spacedim == 1 model = simplexify(CartesianDiscreteModel((0,2pi), (20,)))
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
    (model=model, u=u)
end

function demo_visdata(;kw...)
    model, u = demo_model_fefunction(;kw...)
    trian = Triangulation(model)
    visdata = Visualization.visualization_data(trian, cellfields=Dict("u" =>u))
    return visdata
end

################################################################################
##### TODO: Move to Gridap.Visualization?
################################################################################
function to_visualzation_data(fun, grid)
    _resolve_trian(model::DiscreteModel) = Triangulation(model)
    _resolve_trian(trian) = trian
    trian = _resolve_trian(grid)
    visdata = visualization_data(trian, cellfields=Dict("u" => fun))
    return visdata
end
get_nodalvalues(o::VisualizationData) = only(o.nodaldata).second
get_spacedim(o::VisualizationData) = num_dims(o.grid)
get_valuetype(o::VisualizationData) = typeof(first(get_nodalvalues(o)))

end#module
