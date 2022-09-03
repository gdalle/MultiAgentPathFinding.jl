struct Conflict
    name::String
    a1::Int
    a2::Int
    t1::Int
    t2::Int
    u1::Int
    u2::Int
end

## Find conflicts

function find_conflict(solution::Solution, mapf::MAPF; tol=0)
    for a1 in 1:nb_agents(mapf)
        for a2 in 1:(a1 - 1)
            conflict = find_conflict(a1, a2, solution, mapf; tol=tol)
            if !isnothing(conflict)
                return conflict
            end
        end
    end
    return nothing
end

function count_conflicts(solution::Solution, mapf::MAPF; tol=0)
    c = 0
    for a1 in 1:nb_agents(mapf)
        for a2 in 1:(a1 - 1)
            c += count_conflicts(a1, a2, solution, mapf; tol=tol)
        end
    end
    return c
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

function count_conflicts(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    return count_conflicts(solution[a1], solution[a2], mapf; tol=tol)
end

function find_conflict(timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0)
    if isempty(timed_path1) || isempty(timed_path2)
        return nothing
    end
    ac = find_arrival_conflict(timed_path1, timed_path2, mapf)
    !isnothing(ac) && return ac
    vc = find_vertex_conflict(timed_path1, timed_path2, mapf; tol=tol)
    !isnothing(vc) && return vc
    ec = find_edge_conflict(timed_path1, timed_path2, mapf; tol=tol)
    return ec
end

function count_conflicts(timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0)
    c = 0
    if isempty(timed_path1) || isempty(timed_path2)
        return c
    end
    c += count_arrival_conflicts(timed_path1, timed_path2, mapf)
    c += count_vertex_conflicts(timed_path1, timed_path2, mapf; tol=tol)
    c += count_edge_conflicts(timed_path1, timed_path2, mapf; tol=tol)
    return c
end

function find_arrival_conflict(timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF;)
    tdep1, tarr1 = departure_time(timed_path1), arrival_time(timed_path1)
    tdep2, tarr2 = departure_time(timed_path2), arrival_time(timed_path2)
    l1 = last_vertex(timed_path1)
    l2 = last_vertex(timed_path2)
    l1_conflicts = mapf.vertex_conflicts[l1]
    l2_conflicts = mapf.vertex_conflicts[l2]
    for t1 in max(tdep1, tarr2 + 1):tarr1
        u1 = vertex_at_time(timed_path1, t1)
        exists = insorted(u1, l2_conflicts)
        if exists
            return Conflict("arrival", 0, 0, t1, tarr2, u1, l2)
        end
    end
    for t2 in max(tdep2, tarr1 + 1):tarr2
        u2 = vertex_at_time(timed_path2, t2)
        exists = insorted(u2, l1_conflicts)
        if exists
            return Conflict("arrival", 0, 0, tarr1, t2, l1, u2)
        end
    end
    return nothing
end

function count_arrival_conflicts(
    timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF;
)
    c = 0
    tdep1, tarr1 = departure_time(timed_path1), arrival_time(timed_path1)
    tdep2, tarr2 = departure_time(timed_path2), arrival_time(timed_path2)
    l1 = last_vertex(timed_path1)
    l2 = last_vertex(timed_path2)
    l1_conflicts = mapf.vertex_conflicts[l1]
    l2_conflicts = mapf.vertex_conflicts[l2]
    for t1 in max(tdep1, tarr2 + 1):tarr1
        u1 = vertex_at_time(timed_path1, t1)
        exists = insorted(u1, l2_conflicts)
        if exists
            c += 1
        end
    end
    for t2 in max(tdep2, tarr1 + 1):tarr2
        u2 = vertex_at_time(timed_path2, t2)
        exists = insorted(u2, l1_conflicts)
        if exists
            c += 1
        end
    end
    return c
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

function count_vertex_conflicts(
    timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0
)
    c = 0
    for t1 in departure_time(timed_path1):arrival_time(timed_path1)
        u1 = vertex_at_time(timed_path1, t1)
        u1_conflicts = mapf.vertex_conflicts[u1]
        for t2 in (t1 - tol):(t1 + tol)
            u2 = vertex_at_time(timed_path2, t2)
            isnothing(u2) && continue
            exists = insorted(u2, u1_conflicts)
            if exists
                c += 1
            end
        end
    end
    return c
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

function count_edge_conflicts(
    timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0
)
    c = 0
    for t1 in departure_time(timed_path1):(arrival_time(timed_path1) - 1)
        u1v1 = edge_at_time(timed_path1, t1)
        u1v1_conflicts = mapf.edge_conflicts[u1v1]
        for t2 in (t1 - tol):(t1 + tol)
            u2v2 = edge_at_time(timed_path2, t2)
            isnothing(u2v2) && continue
            exists = insorted(u2v2, u1v1_conflicts)
            if exists
                c += 1
            end
        end
    end
    return c
end
