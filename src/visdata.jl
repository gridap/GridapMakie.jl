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
##### TODO: REMOVE
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
##### Space and Graph
################################################################################
const CatchallSpace = Union{Triangulation, DiscreteModel}
const CatchallSingleField = CellFieldLike
const CatchallField = Union{CatchallSingleField, MultiFieldFEFunction}

struct Space2
    grid_or_model::CatchallSpace
    # Space1(trian::Triangulation) = new(trian)
    # Space1(model::DiscreteModel) = new(model)
end
Space = Space2
Space2(visdata::VisualizationData) = Space(visdata.grid)
Space2(space::Space) = space

struct SingleField2
    space::Space # grid
    node_values::AbstractVector
end
SingleField = SingleField2
FieldOrSpace = Union{SingleField, Space}

function SingleField2(visdata::VisualizationData)
    node_values = only(visdata.nodaldata).second
    return SingleField2(Space(visdata), node_values)
end

function SingleField2(spacelike::CatchallSpace, fieldlike::CatchallSingleField)
    space = Space(spacelike)
    visdata = to_visualization_data(fieldlike, spacelike)
    node_values = get_nodalvalues(visdata)
    @show length(node_values)
    @show length(get_node_coordinates(visdata.grid))
    @show length(get_node_coordinates(spacelike))
    @show length(get_node_coordinates(Triangulation(spacelike)))
    SingleField2(space, node_values)
end

get_space(space::Space) = space
get_space(field::SingleField) = field.space

function spacedim(field_or_space)
    space = get_space(field_or_space)
    num_dims(space.grid_or_model)
end
function graphdim(o::SingleField)
    spacedim(o) + 1
end

function gridap_node_coordinates(field_or_space)
    space = get_space(field_or_space)
    return get_node_coordinates(space.grid_or_model)
end

function gridap_node_values(field::SingleField)
    return field.node_values
end

function gridap_edges(field_or_space)
    space = get_space(field_or_space)
    model = space.grid_or_model
    if !(model isa DiscreteModel)
        @warn "Trying to extract edges from non DiscreteModel. typeof(model) = $(typeof(model))"
    end
    grid1 = Grid(ReferenceFE{1}, model)
    return get_cell_nodes(grid1)
end

function gridap_cells(field_or_space)
    space = get_space(field_or_space)
    return get_cell_nodes(space.grid_or_model)
end

function space_point_type(field_or_space)
    space = get_space(field_or_space)
    return GB.Point{spacedim(space), Float32}
end

function graph_point_type(field)
    GB.Point{graphdim(field), Float32}
end

function vec_type(::VectorValue{n}) where {n}
    return GB.Vec{n, Float32}
end

function vec_type(field)
    x = first(gridap_node_values(field))
    return vec_type(x)
end

function scalar_type(field)
    return Float32
end

scalarize(x) = Float32(x)
scalarize(x::VectorValue{1}) = scalarize(x[1])

function isscalarizable(field::SingleField)
    x = first(gridap_node_values(field))
    isscalarizable(x)
end
isscalarizable(x::VectorValue{1}) = true
isscalarizable(x::VectorValue) = false
isscalarizable(x::TensorValue) = false
isscalarizable(x::Number) = true

function graphpoints(field::SingleField)::AbstractVector{<:GB.Point}
    let P = graph_point_type(field)
        map(gridap_node_coordinates(field.space), gridap_node_values(field)) do pt, val
            P(Tuple(pt)..., scalarize(val))
        end
    end
end

function scalar_node_values(field::SingleField)
    map(scalarize, gridap_node_values(field))
end

function vec_node_values(field::SingleField)
    V = vec_type(field)
    @assert length(gridap_node_values(field)) == length(gridap_node_coordinates(get_space(field)))
    map(gridap_node_values(field)) do vecvalue
        V(Tuple(vecvalue)...)
    end
end

function spacepoints(field_or_space)::AbstractVector{<:GB.Point}
    space = get_space(field_or_space)
    P = space_point_type(space)
    map(gridap_node_coordinates(space)) do pt
        P(Tuple(pt)...)
    end
end

graph_or_space_points(o::Space) = spacepoints(o)
graph_or_space_points(o::SingleField) = graphpoints(o)

function edges_line_face(field_or_space)
    map(gridap_edges(field_or_space)) do edg
        @assert length(edg) == 2
        i1, i2 = edg
        GB.LineFace{UInt32}((i1, i2))
    end
end
graph_or_space_edges(o::SingleField) = graph_edges(o)
graph_or_space_edges(o::Space)       = space_edges(o)

function space_edges(field_or_space)
    o = get_space(field_or_space)
    pts = spacepoints(o)
    return GB.connect(pts, edges_line_face(o))
end

function graph_edges(o::SingleField)
    pts = graphpoints(o)
    return GB.connect(pts, edges_line_face(o))
end

