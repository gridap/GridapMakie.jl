module GridapMakie

export PDEPlot

using Gridap
using AbstractPlotting
using AbstractPlotting: Plot

using Gridap.Visualization
using Gridap.ReferenceFEs
using Gridap.Geometry
using Gridap


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

struct PDEPlot
    visdata::Visualization.VisualizationData
end

function get_nodalvalues(o::PDEPlot)
    get_nodalvalues(o.visdata)
end
function get_nodalvalues(o::Visualization.VisualizationData)
    only(o.nodaldata).second
end

function get_spacedim(o::PDEPlot)
    get_spacedim(o.visdata)
end

get_spacedim(o::Visualization.VisualizationData) = num_dims(o.grid)

function get_valuetype(o::PDEPlot)
    nodalvalues = get_nodalvalues(o)
    typeof(first(nodalvalues))
end

function AbstractPlotting.plot!(p::Plot(PDEPlot))
    pdeplot = to_value(p[1])
    valuetype = get_valuetype(pdeplot)
    spacedim = Val(get_spacedim(pdeplot))
    kw = p.attributes
    _plot_dispatch_spacedim_valuetype(p, pdeplot.visdata, spacedim, valuetype; kw...)
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

function AbstractPlotting.convert_arguments(P::Type{<:Lines}, visdata::Visualization.VisualizationData)
    _convert_arguments_for_lines(P, visdata, get_nodalvalues(visdata))
end
function AbstractPlotting.convert_arguments(P::Type{<:Arrows}, visdata::Visualization.VisualizationData)
    _convert_arguments_for_quiver(P, visdata, get_nodalvalues(visdata))
end
function AbstractPlotting.convert_arguments(P::Type{<:Mesh}, visdata::Visualization.VisualizationData)
    _convert_arguments_for_mesh(P, visdata, get_nodalvalues(visdata))
end


# quiver data
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

function _convert_arguments_for_mesh(P, visdata, nodalvalues)
    makie_coords_spatial = to_makie_matrix(Float64, get_node_coordinates(visdata.grid))
    makie_conn = to_makie_matrix(Int, get_cell_nodes(visdata.grid))
    makie_coords = hcat(makie_coords_spatial, nodalvalues)
    convert_arguments(P, makie_coords, makie_conn) # color
    # mesh!(p, makie_coords, makie_conn, color = nodalvalues, shading = false)
    # wireframe!(p.plots[end][1], color = (:black, 0.6), linewidth = 3)
end

end
