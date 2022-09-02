struct Conflict
    name::String
    a1::Int
    a2::Int
    t1::Int
    t2::Int
    u1::Int
    u2::Int
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
        for t2 in (t1 - tol):(t1 + tol)
            u2 = vertex_at_time(timed_path2, t2)
            isnothing(u2) && continue
            exists = insorted(u2, u1_conflicts)
            if exists
                return Conflict("vertex", 0, 0, t1, t2, u1, u2)
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
        for t2 in (t1 - tol):(t1 + tol)
            u2v2 = edge_at_time(timed_path2, t2)
            isnothing(u2v2) && continue
            exists = insorted(u2v2, u1v1_conflicts)
            if exists
                return Conflict("edge", 0, 0, t1, t2, u1v1...)
            end
        end
    end
    return nothing
end

function find_conflict(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    conflict = find_conflict(solution[a1], solution[a2], mapf; tol=tol)
    if isnothing(conflict)
        return nothing
    else
        return Conflict(
            conflict.name, a1, a2, conflict.t1, conflict.t2, conflict.u1, conflict.u2
        )
    end
end

function find_conflict(solution::Solution, mapf::MAPF; tol=0)
    for a1 in 1:nb_agents(mapf), a2 in 1:(a1 - 1)
        conflict = find_conflict(a1, a2, solution, mapf; tol=tol)
        if !isnothing(conflict)
            return conflict
        end
    end
    return nothing
end
