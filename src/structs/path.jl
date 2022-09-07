"""
    TimedPath

Temporal path through a graph.

# Fields
- `tdep::Int`: departure time
- `path::Vector{Int}`: sequence of vertices
"""
struct TimedPath
    tdep::Int
    path::Vector{Int}
end

"""
    TimedPath(tdep)

Return an empty `TimedPath`.
"""
TimedPath(tdep) = TimedPath(tdep, Int[])

Base.length(timed_path::TimedPath) = length(timed_path.path)
Base.isempty(timed_path::TimedPath) = length(timed_path) == 0

"""
    departure_time(timed_path)

Return the departure time of a `TimedPath`.
"""
departure_time(timed_path::TimedPath) = timed_path.tdep

"""
    arrival_time(timed_path)

Return the departure time of a `TimedPath` plus its number of edges.
"""
arrival_time(timed_path::TimedPath) = timed_path.tdep + length(timed_path) - 1

"""
    remove_arrival_vertex(timed_path)

Cut the last vertex from a `TimedPath`.
"""
function remove_arrival_vertex(timed_path::TimedPath)
    return TimedPath(timed_path.tdep, timed_path.path[1:(end - 1)])
end

"""
    vertex_at_time(timed_path, t)

Return the vertex visited by a `TimedPath` at a given time, throws an error if it does not exist.
"""
function vertex_at_time(timed_path::TimedPath, t)
    k = t - timed_path.tdep + 1
    return timed_path.path[k]
end

"""
    departure_vertex(timed_path)

Return the first vertex of a `TimedPath`.
"""
function departure_vertex(timed_path::TimedPath)
    return vertex_at_time(timed_path, departure_time(timed_path))
end

"""
    arrival_vertex(timed_path)

Return the last vertex of a `TimedPath`.
"""
function arrival_vertex(timed_path::TimedPath)
    return vertex_at_time(timed_path, arrival_time(timed_path))
end

"""
    edge_at_time(timed_path, t)

Return the edge crossed by a `TimedPath` at a given time, throws an error if it does not exist.
"""
function edge_at_time(timed_path::TimedPath, t)
    k = t - timed_path.tdep + 1
    return timed_path.path[k], timed_path.path[k + 1]
end

"""
    concat_path(timed_path1, timed_path2)

Concatenate two compatible `TimedPath`s.
"""
function concat_paths(timed_path1::TimedPath, timed_path2::TimedPath)
    if isempty(timed_path1)
        return timed_path2
    elseif isempty(timed_path2)
        return timed_path1
    else
        @assert arrival_time(timed_path1) == departure_time(timed_path2)
        @assert arrival_vertex(timed_path1) == departure_vertex(timed_path2)
        tdep = departure_time(timed_path1)
        path = vcat(timed_path1.path, timed_path2.path[2:end])
        timed_path = TimedPath(tdep, path)
        return timed_path
    end
end

"""
    exists_in_graph(timed_path, g)

Check that a `TimedPath` is feasible in the graph `g`, i.e. that all vertices and edges exist.
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
    standstill_time(timed_path)

Compute the time at which a `TimedPath` stops moving (which may be earlier than its arrival time if it stays motionless at the end).
"""
function standstill_time(timed_path::TimedPath)
    isempty(timed_path) && return 0
    path = timed_path.path
    k = length(path)
    v = last(path)
    while k > 1
        if path[k - 1] == v
            k -= 1
        else
            break
        end
    end
    return timed_path.tdep + k - 1
end

"""
    path_weight(timed_path, mapf, [edge_weights_vec; tmin, tmax])

Compute the weight of a `TimedPath` through a `MAPF` graph by summing edge weights between times `tmin` and `tmax` (which default to the [`departure_time`](@ref) and [`arrival_time`](@ref)).
"""
function path_weight(
    timed_path::TimedPath,
    mapf::MAPF,
    edge_weights_vec::AbstractVector{W}=mapf.edge_weights_vec;
    tmin=departure_time(timed_path),
    tmax=arrival_time(timed_path),
) where {W}
    c = zero(W)
    for t in tmin:(tmax - 1)
        u, v = edge_at_time(timed_path, t)
        e = mapf.edge_indices[u, v]
        c += edge_weights_vec[e]
    end
    return c
end

"""
    flowtime(timed_path, mapf[, edge_weights_vec])

Compute the weight of a `TimedPath` through a `MAPF` graph from its [`departure_time`](@ref) until its [`standstill_time`](@ref).
"""
function flowtime(
    timed_path::TimedPath,
    mapf::MAPF,
    edge_weights_vec::AbstractVector{W}=mapf.edge_weights_vec,
) where {W}
    return path_weight(timed_path, mapf, edge_weights_vec; tmax=standstill_time(timed_path))
end
