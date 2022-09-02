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

Base.length(timed_path::TimedPath) = length(timed_path.path)

departure_time(timed_path::TimedPath) = timed_path.tdep
arrival_time(timed_path::TimedPath) = timed_path.tdep + length(timed_path) - 1

first_vertex(timed_path::TimedPath) = first(timed_path.path)
last_vertex(timed_path::TimedPath) = last(timed_path.path)

function vertex_at_time(timed_path::TimedPath, t)
    k = t - timed_path.tdep + 1
    if k in 1:length(timed_path)
        return timed_path.path[k]
    else
        return nothing
    end
end

function edge_at_time(timed_path::TimedPath, t)
    k = t - timed_path.tdep + 1
    if k in 1:(length(timed_path) - 1)
        return timed_path.path[k], timed_path.path[k + 1]
    else
        return nothing
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

## Conflicts

function find_conflict(timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0)
    vc = find_vertex_conflict(timed_path1, timed_path2, mapf; tol=tol)
    !isnothing(vc) && return vc
    ec = find_edge_conflict(timed_path1, timed_path2, mapf; tol=tol)
    return ec
end

function find_vertex_conflict(
    timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0
)
    for t1 in departure_time(timed_path1):arrival_time(timed_path1)
        u1 = vertex_at_time(timed_path1, t1)
        haskey(mapf.vertex_conflicts, u1) || continue
        u1_conflicts = mapf.vertex_conflicts[u1]
        isempty(u1_conflicts) && continue
        for t2 in (t1 - tol):(t1 + tol)
            u2 = vertex_at_time(timed_path2, t2)
            isnothing(u2) && continue
            if insorted(u2, u1_conflicts)
                return t1, t2
            end
        end
    end
    return nothing
end

function find_edge_conflict(
    timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0
)
    for t1 in departure_time(timed_path1):(arrival_time(timed_path1) - 1)
        u1v1 = edge_at_time(timed_path1, t1)
        haskey(mapf.edge_conflicts, u1v1) || continue
        u1v1_conflicts = mapf.edge_conflicts[u1v1]
        isempty(u1v1_conflicts) && continue
        for t2 in (t1 - tol):(t1 + tol)
            u2v2 = edge_at_time(timed_path2, t2)
            isnothing(u2v2) && continue
            if insorted(u2v2, u1v1_conflicts)
                return t1, t2
            end
        end
    end
    return nothing
end
