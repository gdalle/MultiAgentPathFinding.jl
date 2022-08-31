"""
    TimedPath

Temporal path through a graph.

# Fields
- `t0::Int`
- `path::Vector{Int}`
"""
struct TimedPath
    t0::Int
    path::Vector{Int}
end

Base.length(timed_path::TimedPath) = length(timed_path.path)
departure_time(timed_path::TimedPath) = timed_path.t0
arrival_time(timed_path::TimedPath) = timed_path.t0 + length(timed_path) - 1

first_vertex(timed_path::TimedPath) = first(timed_path.path)
last_vertex(timed_path::TimedPath) = last(timed_path.path)

function vertex_at_time(timed_path::TimedPath, t::Integer)
    k = t - timed_path.t0 + 1
    if k in 1:length(timed_path)
        return timed_path.path[k]
    else
        return nothing
    end
end

function edge_at_time(timed_path::TimedPath, t::Integer)
    k = t - timed_path.t0 + 1
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
