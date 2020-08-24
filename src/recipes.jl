################################################################################
##### Dispatch Pipeline
################################################################################
const CatchallSpace = Union{Triangulation, DiscreteModel}
const CatchallSingleField = CellFieldLike
const CatchallField = Union{CatchallSingleField, MultiFieldFEFunction}

function AP.plottype(space::CatchallSpace)
    AP.plottype(Space(space))
end
function AP.plottype(space::CatchallSpace, field::CatchallField)
    AP.plottype(SingleField(space, field))
end
function AP.plottype(space::Space)
    # dim = spacedim(space)
    Wireframe
end
function AP.plottype(field::SingleField)
    dim = spacedim(field)
    PlotType = if isscalarizable(field)
        if dim == 1
            Lines
        elseif dim == 2
            Mesh
        elseif dim == 3
            MeshScatter
        else
            error("dim = $dim")
        end
    else
        Arrows
    end
    @show PlotType
    PlotType
end

function AP.convert_arguments(P::Type{<:AP.AbstractPlot}, space::CatchallSpace, f::CatchallField)
    o = SingleField(space, f)
    AP.convert_arguments(P, o)
end

function AP.convert_arguments(P::Type{<:AP.AbstractPlot}, space::CatchallSpace)
    AP.convert_arguments(P, Space(space))
end

function AP.convert_arguments(P::AP.PointBased, o::FieldOrSpace)
    return AP.convert_arguments(P, graph_or_space_points(o))
end
function AP.convert_arguments(P::Type{<:Arrows}, o::SingleField)
    @argcheck spacedim(o) in 2:3
    v = vec_node_values(o)
    pts = spacepoints(o)
    @assert length(pts) == length(v)
    AP.convert_arguments(P, pts, v)
end
function AP.convert_arguments(P::Type{<:Wireframe}, o::FieldOrSpace)
    (graph_or_space_edges(o),)
end
function AP.convert_arguments(P::Type{<:Mesh}, o::FieldOrSpace)
    pts = graph_or_space_points(o)
    cells = gridap_cells(o)
    cell = first(cells)
    N = length(cell)
    FaceType = GB.NgonFace{N, UInt32}
    faces = map(FaceType, cells)
    faceview = GB.connect(pts, faces)
    msh = GB.Mesh(faceview)
    AP.convert_arguments(P, msh)
end

################################################################################
##### Arrows
################################################################################

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
