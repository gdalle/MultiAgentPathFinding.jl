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

Return an empty `TimedPath`.
"""
TimedPath(tdep::Integer) = TimedPath(tdep, Int[])

Base.length(timed_path::TimedPath) = length(timed_path.path)
Base.isempty(timed_path::TimedPath) = isempty(timed_path.path)

"""
$(TYPEDSIGNATURES)

Return the departure time of `timed_path`.
"""
departure_time(timed_path::TimedPath) = timed_path.tdep

"""
$(TYPEDSIGNATURES)

Return the departure time of `timed_path` plus its number of edges.
"""
arrival_time(timed_path::TimedPath) = timed_path.tdep + length(timed_path) - 1

"""
$(TYPEDSIGNATURES)

Return the vertex visited by `timed_path` at a given time `t`, throws an error if it does not exist.
"""
function vertex_at_time(timed_path::TimedPath, t::Integer)
    k = t - timed_path.tdep + 1
    return timed_path.path[k]
end

"""
$(TYPEDSIGNATURES)

Return the first vertex of `timed_path`.
"""
function departure_vertex(timed_path::TimedPath)
    return vertex_at_time(timed_path, departure_time(timed_path))
end

"""
$(TYPEDSIGNATURES)

Return the last vertex of `timed_path`.
"""
function arrival_vertex(timed_path::TimedPath)
    return vertex_at_time(timed_path, arrival_time(timed_path))
end

"""
$(TYPEDSIGNATURES)

Return the edge crossed by `timed_path` at a given time `t`, throws an error if it does not exist.
"""
function edge_at_time(timed_path::TimedPath, t::Integer)
    k = t - timed_path.tdep + 1
    return timed_path.path[k], timed_path.path[k + 1]
end

"""
$(TYPEDSIGNATURES)

Check that `timed_path` is feasible in the graph `g`, i.e. that all vertices and edges exist.
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

Sum the costs of all the edges in `timed_path`.
Costs are computed within `mapf` for agent `a`.
"""
function path_cost(timed_path::TimedPath, a::Integer, mapf::MAPF)
    (; edge_costs) = mapf
    c = zero(eltype(edge_costs))
    for t in departure_time(timed_path):(arrival_time(timed_path) - 1)
        u, v = edge_at_time(timed_path, t)
        c += edge_cost(edge_costs, u, v, a, t)
    end
    return c
end
