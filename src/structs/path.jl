"""
$(TYPEDEF)

Temporal path through a graph.

# Fields

$(TYPEDFIELDS)
"""
struct TimedPath
    "departure time"
    tdep::Int
    "sequence of vertices"
    path::Vector{Int}
end

"""
$(TYPEDSIGNATURES)

Return an empty timed path.
"""
TimedPath(tdep::Integer) = TimedPath(tdep, Int[])

Base.length(timed_path::TimedPath) = length(timed_path.path)
Base.isempty(timed_path::TimedPath) = length(timed_path) == 0

"""
$(TYPEDSIGNATURES)

Return the departure time of a timed path.
"""
departure_time(timed_path::TimedPath) = timed_path.tdep

"""
$(TYPEDSIGNATURES)

Return the departure time of a timed path plus its number of edges.
"""
arrival_time(timed_path::TimedPath) = timed_path.tdep + length(timed_path) - 1

"""
$(TYPEDSIGNATURES)

Return the vertex visited by a timed path at a given time, throws an error if it does not exist.
"""
function vertex_at_time(timed_path::TimedPath, t::Integer)
    k = t - timed_path.tdep + 1
    return timed_path.path[k]
end

"""
$(TYPEDSIGNATURES)

Return the first vertex of a timed path.
"""
function departure_vertex(timed_path::TimedPath)
    return vertex_at_time(timed_path, departure_time(timed_path))
end

"""
$(TYPEDSIGNATURES)

Return the last vertex of a timed path.
"""
function arrival_vertex(timed_path::TimedPath)
    return vertex_at_time(timed_path, arrival_time(timed_path))
end

"""
$(TYPEDSIGNATURES)

Return the edge crossed by a timed path at a given time, throws an error if it does not exist.
"""
function edge_at_time(timed_path::TimedPath, t::Integer)
    k = t - timed_path.tdep + 1
    return timed_path.path[k], timed_path.path[k + 1]
end

"""
$(TYPEDSIGNATURES)

Check that a timed path is feasible in the graph `g`, i.e. that all vertices and edges exist.
"""
function exists_in_graph(timed_path::TimedPath, g::AbstractGraph)
    for t in departure_time(timed_path):arrival_time(timed_path)
        u = vertex_at_time(timed_path, t)
        has_vertex(g, u) || return false
    end
    for t in departure_time(timed_path):(arrival_time(timed_path) - 1)
        u, v = edge_at_time(timed_path, t)
        has_edge(g, u, v) || return false
    end
    return true
end

## Cost

"""
$(TYPEDSIGNATURES)

Compute the weight of a timed path by summing edge weights between times `tmin` and `tmax` (which default to the departure and arrival time).
"""
function path_cost(
    timed_path::TimedPath,
    mapf::MAPF{W};
    tmin::Integer=departure_time(timed_path),
    tmax::Integer=arrival_time(timed_path),
) where {W}
    c = zero(W)
    for t in tmin:(tmax - 1)
        u, v = edge_at_time(timed_path, t)
        c += mapf.edge_weights[u, v]
    end
    return c
end
