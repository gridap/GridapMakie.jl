module GridapMakie

export PDEPlot

using Gridap
using ConstructionBase
using AbstractPlotting
const AP = AbstractPlotting

using Gridap.Visualization: VisualizationData, Visualization, visualization_data
using Gridap.ReferenceFEs
using Gridap.Geometry
using Gridap.Geometry: CellFieldLike
using Gridap.MultiField: MultiFieldFEFunction
using Gridap


################################################################################
##### TODO: Move to Gridap.Visualization?
################################################################################

_resolve_trian(model::DiscreteModel) = Triangulation(model)
_resolve_trian(trian) = trian
function _resolve_cellfields(fun)
    Dict("u" => fun)
end
function _resolve_cellfields(fun::MultiFieldFEFunction)
    Dict("u$i" => fi for (i, fi) in enumerate(fun))
end

function to_visualization_data(fun, grid)
    # TODO merge this function into visualization_data?
    trian = _resolve_trian(grid)
    cellfields = _resolve_cellfields(fun)
    visdata = visualization_data(trian, cellfields=cellfields)
    return visdata
end
function to_visualization_data(grid)
    trian = _resolve_trian(grid)
    visdata = visualization_data(trian, cellfields=Dict())
end
get_nodalvalues(o::VisualizationData) = only(o.nodaldata).second
get_spacedim(o::VisualizationData) = num_dims(o.grid)
get_valuetype(o::VisualizationData) = typeof(first(get_nodalvalues(o)))

################################################################################
##### Dispatch Pipeline
################################################################################

# Dispatch strategy
# Given a call `plot(arg...)` we first decide to take ownership by overloading
# AP.plottype(::GridapCares, ::AboutTheseArgs) = PDEPlot
#
# Then the arguments are standardized into `VisualizationData` by overloading
#
# AP.convert_arguments(::Type{<:PDEPlot}, args...)
#
# For VisualizationData we have various recipes like
#
# AP.convert_arguments(P::AP.PointBased, visdata::VisualizationData)
#
# Finally `plot!(::PDEPlot)` is overloaded to magially dispatch to an appropriate recipe
# based on `spacedimension`, `valuetype` etc. For instance a 1d scalar field should
# use `Lines`, while a 2d vector field should use `Arrows` etc.

"""
    PDEPlot

The job of `PDEPlot` is to choose a sane visualization of Gridap function like objects.
E.g. produce `Arrows` for a vector field and lines for a scalar field in one space dimension etc.
"""
@recipe(PDEPlot, visualization_data) do scene
    Theme()
end

const CatchallSpace = Union{Triangulation, DiscreteModel}
const CatchallSingleField = CellFieldLike
const CatchallField = Union{CatchallSingleField, MultiFieldFEFunction}
AP.plottype(::CatchallSpace) = PDEPlot
AP.plottype(::CatchallField, ::CatchallSpace) = PDEPlot
AP.plottype(::VisualizationData) = PDEPlot

function AP.convert_arguments(P::Type{<:AP.AbstractPlot}, f::CatchallField, space::CatchallSpace)
    AP.convert_arguments(P, to_visualization_data(f, space))
end

function AP.convert_arguments(P::Type{<:AP.AbstractPlot}, space::CatchallSpace)
    AP.convert_arguments(P, to_visualization_data(space))
end

function AP.convert_arguments(P::AP.PointBased, visdata::VisualizationData)
    _convert_arguments_for_lines(P, visdata, get_nodalvalues(visdata))
end
function AP.convert_arguments(P::Type{<:Arrows}, visdata::VisualizationData)
    _convert_arguments_for_quiver(P, visdata, get_nodalvalues(visdata))
end
function AP.convert_arguments(P::Type{<:Mesh}, visdata::VisualizationData)
    if ismodel(visdata) #visdata contains only a triangulation
        _convert_arguments_for_mesh(P, visdata)
    else
        _convert_arguments_for_mesh(P, visdata, get_nodalvalues(visdata))
    end
end

# function AP.convert_arguments(::Type{<:PDEPlot},
#         fun::CatchallField,
#         grid::CatchallSpace,
#     )
#     visdata = to_visualization_data(fun, grid)
#     return convert_arguments(PDEPlot, visdata)
# end

# function AP.convert_arguments(::Type{<:PDEPlot}, grid::CatchallSpace)
#     visdata = to_visualization_data(grid)
#     return convert_arguments(PDEPlot, visdata)
# end

function _plot_model!(p, visdata)
    kw = p.attributes
    mesh!(p, visdata; kw...)
end

ismultifield(visdata::VisualizationData) = length(visdata.nodaldata) > 1
issinglefield(visdata::VisualizationData) = length(visdata.nodaldata) == 1
ismodel(visdata::VisualizationData) = isempty(visdata.nodaldata)

function AP.plot!(p::PDEPlot{<:Tuple{VisualizationData}})
    visdata = to_value(p[:visualization_data])::VisualizationData
    if ismodel(visdata)
        _plot_model!(p, visdata)
    elseif issinglefield(visdata)
        _plot_single_field!(p, visdata)
    else
        @assert ismultifield(visdata)
        for (key, nodelvals) in visdata.nodaldata
            visdata_key = setproperties(visdata, nodaldata=Dict(key => nodelvals))
            _plot_single_field!(p, visdata_key)
        end
    end
    return p
end
function _plot_single_field!(p, visdata)
    valuetype = get_valuetype(visdata)
    spacedim = Val(get_spacedim(visdata))
    kw = p.attributes
    _plot_dispatch_spacedim_valuetype!(p, visdata, spacedim, valuetype; kw...)
end

function _plot_dispatch_spacedim_valuetype!(
    p,
    visdata,
    spacedim::Val{1},
    valuetype::Type{<:VectorValue{1}};
    kw...)
    lines!(p, visdata; kw...)
end
function _plot_dispatch_spacedim_valuetype!(p, visdata, spacedim, valuetype; kw...)
    _plot_dispatch_valuetype!(p, visdata, valuetype; kw...)
end

function _plot_dispatch_valuetype!(p, visdata, valuetype::Type{<:Union{VectorValue, TensorValue}}; kw...)
    quiver!(p,visdata; kw...)
end

function _plot_dispatch_valuetype!(p, visdata, valuetype; kw...)
    spacedim = Val(get_spacedim(visdata))
    _plot_dispatch_spacedim!(p, visdata, spacedim; kw...)
end

function _plot_dispatch_spacedim!(p, visdata, spacedim::Val{1}; kw...)
    lines!(p, visdata; kw...)
end

function _plot_dispatch_spacedim!(p, visdata, spacedim::Val{2};
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
##### PointBased (covers Lines, Scatter etc.)
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
function _convert_arguments_for_mesh(P, visdata)
    @assert isempty(visdata.nodaldata)
    makie_coords = to_makie_matrix(Float64, get_node_coordinates(visdata.grid))
    makie_conn = to_makie_matrix(Int, get_cell_nodes(visdata.grid))
    convert_arguments(P, makie_coords, makie_conn) # color
end

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
function demo_data_single_field(;spacedim::Integer, valuetype::Type)
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
    c1,c2,c3 = randn(3)
    f = if T isa VectorValue{1}
            f = pt -> T(c1*sin(pt[i1]))
        elseif T isa VectorValue{2}
            f = pt -> T(c1*sin(pt[i1]), c2*cos(pt[i2]))
        elseif T isa VectorValue{3}
            f = pt -> T(c1*sin(pt[i1]), c2*cos(pt[i2]), c3*pt[i3])
        elseif T isa VectorValue
            error()
        elseif T isa TensorValue
            error()
        elseif spacedim == 1
            pt -> c1*sin(pt[1]) + c2
        elseif spacedim == 2
            pt -> c1*sin(pt[1]) * cos(pt[2]) + c2
        elseif spacedim == 3
            pt -> c1*sin(pt[1]) * cos(pt[2]) * pt[3] + c2
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
