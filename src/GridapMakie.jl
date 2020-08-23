module GridapMakie

using Gridap
using ArgCheck
using ConstructionBase
using AbstractPlotting
const AP = AbstractPlotting
import GeometryBasics
const GB = GeometryBasics

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
function to_visualization_data(visdata::VisualizationData)
    visdata
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

ismultifield(visdata::VisualizationData) = length(visdata.nodaldata) > 1
issinglefield(visdata::VisualizationData) = length(visdata.nodaldata) == 1
ismodel(visdata::VisualizationData) = isempty(visdata.nodaldata)
################################################################################
##### Dispatch Pipeline
################################################################################
const CatchallSpace = Union{Triangulation, DiscreteModel}
const CatchallSingleField = CellFieldLike
const CatchallField = Union{CatchallSingleField, MultiFieldFEFunction}

struct IsModel; spacedim::Int; end
struct IsSingleField
    spacedim::Int
    scalarizable::Bool
    valuetype::Type
end
struct IsMultiField
    spacedim::Int
end

function dispatchinfo(visdata::VisualizationData)
    spacedim = num_dims(visdata.grid)
    if isempty(visdata.nodaldata)
        IsModel(spacedim)
    elseif length(visdata.nodaldata) == 1
        x = first(get_nodalvalues(visdata))
        scalarizable = length(x) == 1
        valuetype = typeof(x)
        IsSingleField(spacedim, scalarizable, valuetype)
    else
        IsMultiField(spacedim)
    end
end

function AP.plottype(space::CatchallSpace)
    AP.plottype(to_visualization_data(space))
end
function AP.plottype(field::CatchallField, space::CatchallSpace)
    AP.plottype(to_visualization_data(field, space))
end
function AP.plottype(visdata::VisualizationData)
    info = dispatchinfo(visdata)
    _plottype(info)
end
function _plottype(info::IsModel)
    Wireframe
end
function _plottype(info::IsSingleField)
    if info.scalarizable
        if info.spacedim == 1
            Lines
        elseif info.spacedim == 2
            Mesh
        else
            MeshScatter
        end
    else
        Arrows
    end
end
function _plottype(::IsMultiField)
    MultiFieldPlot
end

function AP.convert_arguments(P::Type{<:AP.AbstractPlot}, f::CatchallField, space::CatchallSpace)
    visdata = to_visualization_data(f, space)
    AP.convert_arguments(P, visdata)
end

function AP.convert_arguments(P::Type{<:AP.AbstractPlot}, space::CatchallSpace)
    AP.convert_arguments(P, to_visualization_data(space))
end

function AP.convert_arguments(P::AP.PointBased, visdata::VisualizationData)
    _convert_arguments_for_lines(P, visdata, get_nodalvalues(visdata))
end
function AP.convert_arguments(P::Type{<:Arrows}, visdata::VisualizationData)
    _convert_arguments_for_arrows(P, visdata, get_nodalvalues(visdata))
end
function AP.convert_arguments(P::Type{<:Mesh}, visdata::VisualizationData)
    if ismodel(visdata) #visdata contains only a triangulation
        _convert_arguments_for_mesh(P, visdata)
    else
        _convert_arguments_for_mesh(P, visdata, get_nodalvalues(visdata))
    end
end

################################################################################
##### MultiFieldPlot
################################################################################
@recipe(MultiFieldPlot, visualization_data) do scene
    Theme()
end

function AP.plot!(p::AP.Plot(MultiFieldPlot))
    visdata = to_value(p[:visualization_data])::VisualizationData
    @argcheck ismultifield(visdata)
    for (key, nodelvals) in visdata.nodaldata
        visdata_key = setproperties(visdata, nodaldata=Dict(key => nodelvals))
        plot!(p, Attributes(p), visdata_key)
    end
    return p
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

_PV2 = Union{GB.Point2f0, GB.Vec2f0}
_PV3 = Union{GB.Point3f0, GB.Vec3f0}
_trailing_zeros(P, xyz::Tuple) = __trailing_zeros_splat(P, xyz...)
__trailing_zeros_splat(P::Type{<:_PV2}, x) = P(x, 0f0)
__trailing_zeros_splat(P::Type{<:_PV2}, x, y) = P(x, y)
__trailing_zeros_splat(P::Type{<:_PV3}, x, ) = P(x, 0f0, 0f0)
__trailing_zeros_splat(P::Type{<:_PV3}, x, y) = P(x, y, 0f0)
__trailing_zeros_splat(P::Type{<:_PV3}, x, y, z) = P(x, y, z)

function _convert_arguments_for_arrows(P, visdata, nodalvalues)
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
    N = max(spacedim, vecdim, 2)
    Point = GB.Point{N, Float32}
    node_coords = get_node_coordinates(visdata.grid)
    pts = _trailing_zeros.(Ref(Point), Tuple.(node_coords))
    Vec = GB.Vec{N, Float32}
    vecs = _trailing_zeros.(Ref(Vec), Tuple.(nodalvalues))
    return (pts, vecs)
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
    pts = map(get_node_coordinates(visdata.grid), nodalvalues) do ptx, y
        GB.Point2f0(ptx[1], single(y))
    end
    (pts,)
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
##### Wireframe
################################################################################
function AP.plot!(p::Wireframe{<:Tuple{VisualizationData}})
    visdata = to_value(p[1])::VisualizationData
    Point = if dispatchinfo(visdata) isa IsModel
        GB.Point2f0
    else
        GB.Point3f0
    end
    lines = _convert_arguments_for_linesegments(Point, visdata)
    linesegments!(p, Attributes(p), lines)
end

@noinline function _convert_arguments_for_linesegments(
        ::Type{Point}, visdata
    ) where {Point <: Union{GB.Point2f0, GB.Point3f0}}

    @argcheck dispatchinfo(visdata) isa Union{IsModel, IsSingleField}
    @argcheck dispatchinfo(visdata).spacedim == 2
    function build_point(Point::Type{GB.Point2f0}, index, node_coords, _)
        x,y = Tuple(node_coords[index])
        return Point(x,y)
    end
    function build_point(Point::Type{GB.Point3f0}, index, node_coords, node_vals)
        x,y = Tuple(node_coords[index])
        z = node_vals[index]
        return Point(x,y, z)
    end
    cells = get_cell_nodes(visdata.grid)
    node_coords = get_node_coordinates(visdata.grid)::AbstractVector{<:VectorValue}
    node_vals = if Point == GB.Point2f0
        nothing
    else
        get_nodalvalues(visdata)
    end
    lines = NTuple{2, Point}[]
    first(cells)::AbstractVector{<:Integer}
    # each cell is encoded list of indices of
    # the vertex points
    for cell in cells
        # e.g. cell = [4,5,6] describes a triangle with vertices of pt[5], pt[5], pts[6]
        for iistart in eachindex(cell)
            iistop = iistart + 1
            istart = cell[iistart]
            istop = get(cell, iistop, first(cell))
            pt1 = build_point(Point, istart, node_coords, node_vals)
            pt2 = build_point(Point, istop , node_coords, node_vals)
            push!(lines, (pt1, pt2))
        end
    end
    return lines
end

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
