"""
    TimedPath

Temporal path through a graph.

# Fields
- `tdep::Int`
- `path::Vector{Int}`
"""
struct TimedPath
    tdep::Int
    path::Vector{Int}
end

TimedPath(tdep) = TimedPath(tdep, Int[])

Base.length(timed_path::TimedPath) = length(timed_path.path)
Base.isempty(timed_path::TimedPath) = length(timed_path) == 0

departure_time(timed_path::TimedPath) = timed_path.tdep
arrival_time(timed_path::TimedPath) = timed_path.tdep + length(timed_path) - 1

function remove_arrival_vertex(timed_path::TimedPath)
    return TimedPath(timed_path.tdep, timed_path.path[1:(end - 1)])
end

function vertex_at_time(timed_path::TimedPath, t)
    k = t - timed_path.tdep + 1
    if k in 1:length(timed_path)
        return timed_path.path[k]
    else
        return nothing
    end
end

function departure_vertex(timed_path::TimedPath)
    return vertex_at_time(timed_path, departure_time(timed_path))
end

function arrival_vertex(timed_path::TimedPath)
    return vertex_at_time(timed_path, arrival_time(timed_path))
end

function edge_at_time(timed_path::TimedPath, t)
    k = t - timed_path.tdep + 1
    if k in 1:(length(timed_path) - 1)
        return timed_path.path[k], timed_path.path[k + 1]
    else
        return nothing
    end
end

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

function flowtime(
    timed_path::TimedPath,
    mapf::MAPF,
    edge_weights_vec::AbstractVector{W}=mapf.edge_weights_vec,
) where {W}
    return path_weight(timed_path, mapf, edge_weights_vec; tmax=standstill_time(timed_path))
end
