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
    vc = find_vertex_conflict(a1, a2, solution, mapf; tol=tol)
    !isnothing(vc) && return vc
    ec = find_edge_conflict(a1, a2, solution, mapf; tol=tol)
    !isnothing(ec) && return ec
    ac = find_arrival_conflict(a1, a2, solution, mapf)
    !isnothing(ac) && return ac
    return nothing
end

function count_conflicts(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    vcc = count_vertex_conflicts(a1, a2, solution, mapf; tol=tol)
    ecc = count_edge_conflicts(a1, a2, solution, mapf; tol=tol)
    acc = count_arrival_conflicts(a1, a2, solution, mapf)
    return vcc + ecc + acc
end

function find_vertex_conflict(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    timed_path1 = solution[a1]
    timed_path2 = solution[a2]
    for t1 in departure_time(timed_path1):arrival_time(timed_path1)
        u1 = vertex_at_time(timed_path1, t1)
        u1_conflicts = mapf.vertex_conflicts[u1]
        for t2 in (t1 - tol):(t1 + tol)
            u2 = vertex_at_time(timed_path2, t2)
            isnothing(u2) && continue
            exists = insorted(u2, u1_conflicts)
            if exists
                return Conflict("vertex", a1, a2, t1, t2, u1, u2)
            end
        end
    end
    return nothing
end

function count_vertex_conflicts(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    c = 0
    timed_path1 = solution[a1]
    timed_path2 = solution[a2]
    for t1 in departure_time(timed_path1):arrival_time(timed_path1)
        u1 = vertex_at_time(timed_path1, t1)
        u1_conflicts = mapf.vertex_conflicts[u1]
        for t2 in (t1 - tol):(t1 + tol)
            u2 = vertex_at_time(timed_path2, t2)
            isnothing(u2) && continue
            exists = insorted(u2, u1_conflicts)
            c += exists
        end
    end
    return c
end

function find_edge_conflict(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    timed_path1 = solution[a1]
    timed_path2 = solution[a2]
    for t1 in departure_time(timed_path1):(arrival_time(timed_path1) - 1)
        u1v1 = edge_at_time(timed_path1, t1)
        u1v1_conflicts = mapf.edge_conflicts[u1v1]
        for t2 in (t1 - tol):(t1 + tol)
            u2v2 = edge_at_time(timed_path2, t2)
            isnothing(u2v2) && continue
            exists = insorted(u2v2, u1v1_conflicts)
            if exists
                return Conflict("edge", a1, a2, t1, t2, u1v1...)
            end
        end
    end
    return nothing
end

function count_edge_conflicts(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    c = 0
    timed_path1 = solution[a1]
    timed_path2 = solution[a2]
    for t1 in departure_time(timed_path1):(arrival_time(timed_path1) - 1)
        u1v1 = edge_at_time(timed_path1, t1)
        u1v1_conflicts = mapf.edge_conflicts[u1v1]
        for t2 in (t1 - tol):(t1 + tol)
            u2v2 = edge_at_time(timed_path2, t2)
            isnothing(u2v2) && continue
            exists = insorted(u2v2, u1v1_conflicts)
            c += exists
        end
    end
    return c
end

function find_arrival_conflict(a1, a2, solution::Solution, mapf::MAPF;)
    mapf.stay_at_arrival || return nothing
    timed_path1 = solution[a1]
    timed_path2 = solution[a2]
    tdep1, tarr1 = departure_time(timed_path1), arrival_time(timed_path1)
    tdep2, tarr2 = departure_time(timed_path2), arrival_time(timed_path2)
    arr1 = arrival_vertex(timed_path1)
    if arr1 == mapf.arrivals[a1]
        arr1_conflicts = mapf.vertex_conflicts[arr1]
        for t2 in max(tdep2, tarr1 + 1):tarr2
            u2 = vertex_at_time(timed_path2, t2)
            exists = insorted(u2, arr1_conflicts)
            if exists
                return Conflict("arrival", a1, a2, tarr1, t2, arr1, u2)
            end
        end
    end
    arr2 = arrival_vertex(timed_path2)
    if arr2 == mapf.arrivals[a2]
        arr2_conflicts = mapf.vertex_conflicts[arr2]
        for t1 in max(tdep1, tarr2 + 1):tarr1
            u1 = vertex_at_time(timed_path1, t1)
            exists = insorted(u1, arr2_conflicts)
            if exists
                return Conflict("arrival", a1, a2, t1, tarr2, u1, arr2)
            end
        end
    end
    return nothing
end

function count_arrival_conflicts(a1, a2, solution::Solution, mapf::MAPF;)
    c = 0
    mapf.stay_at_arrival || return 0
    timed_path1 = solution[a1]
    timed_path2 = solution[a2]
    tdep1, tarr1 = departure_time(timed_path1), arrival_time(timed_path1)
    tdep2, tarr2 = departure_time(timed_path2), arrival_time(timed_path2)
    arr1 = arrival_vertex(timed_path1)
    if arr1 == mapf.arrivals[a1]
        arr1_conflicts = mapf.vertex_conflicts[arr1]
        for t2 in max(tdep2, tarr1 + 1):tarr2
            u2 = vertex_at_time(timed_path2, t2)
            exists = insorted(u2, arr1_conflicts)
            c += exists
        end
    end
    arr2 = arrival_vertex(timed_path2)
    if arr2 == mapf.arrivals[a2]
        arr2_conflicts = mapf.vertex_conflicts[arr2]
        for t1 in max(tdep1, tarr2 + 1):tarr1
            u1 = vertex_at_time(timed_path1, t1)
            exists = insorted(u1, arr2_conflicts)
            c += exists
        end
    end
    return c
end
