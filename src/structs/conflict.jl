struct Conflict
    name::String
    t1::Int
    t2::Int
    u1::Int
    u2::Int
end

## Conflicts

function find_conflict(timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0)
    ac = find_arrival_conflict(timed_path1, timed_path2, mapf)
    !isnothing(ac) && return ac
    vc = find_vertex_conflict(timed_path1, timed_path2, mapf; tol=tol)
    !isnothing(vc) && return vc
    ec = find_edge_conflict(timed_path1, timed_path2, mapf; tol=tol)
    return ec
end

function find_arrival_conflict(
    timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0
)
    mapf.stay_at_arrival || return nothing
    l2 = last_vertex(timed_path2)
    if !isnothing(l2)
        for t1 in departure_time(timed_path1):arrival_time(timed_path1)
            u1 = vertex_at_time(timed_path1, t1)
            haskey(mapf.vertex_conflicts, u1) || continue
            u1_conflicts = mapf.vertex_conflicts[u1]
            if insorted(l2, u1_conflicts)
                return Conflict("arrival", t1, arrival_time(timed_path2), u1, l2)
            end
        end
    end
    l1 = last_vertex(timed_path1)
    if !isnothing(l1)
        for t2 in departure_time(timed_path2):arrival_time(timed_path2)
            u2 = vertex_at_time(timed_path2, t2)
            haskey(mapf.vertex_conflicts, u2) || continue
            u2_conflicts = mapf.vertex_conflicts[u2]
            if insorted(l1, u2_conflicts)
                return Conflict("arrival", arrival_time(timed_path1), t2, l1, u2)
            end
        end
    end
    return nothing
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
                return Conflict("vertex", t1, t2, u1, u2)
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
                return Conflict("edge", t1, t2, u1v1...)
            end
        end
    end
    return nothing
end

function find_conflict(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    return find_conflict(solution[a1], solution[a2], mapf; tol=tol)
end

function find_conflict(a1, solution::Solution, mapf::MAPF; tol=0)
    for a2 in 1:nb_agents(mapf)
        if a2 != a1
            conflict = find_conflict(a1, a2, solution, mapf; tol=tol)
            if !isnothing(conflict)
                return conflict
            end
        end
    end
    return nothing
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
