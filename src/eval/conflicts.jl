## Between paths

function find_conflict(timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0)
    t01, path1 = timed_path1.t0, timed_path1.path
    t02, path2 = timed_path2.t0, timed_path2.path
    for (k1, v1) in enumerate(path1)
        t1 = t01 + k1 - 1
        conflicts = mapf.vertex_conflicts[v1]
        for t2 in (t1 - tol):(t1 + tol)
            k2 = t2 - t02 + 1
            if 1 <= k2 <= length(path2)
                v2 = path2[k2]
                if insorted(v2, conflicts)
                    return (t1, v1), (t2, v2)
                end
            end
        end
    end
    return nothing
end

function count_conflicts(timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0)
    c = 0
    t01, path1 = timed_path1.t0, timed_path1.path
    t02, path2 = timed_path2.t0, timed_path2.path
    for (k1, v1) in enumerate(path1)
        t1 = t01 + k1 - 1
        conflicts = mapf.vertex_conflicts[v1]
        for t2 in (t1 - tol):(t1 + tol)
            k2 = t2 - t02 + 1
            if 1 <= k2 <= length(path2)
                v2 = path2[k2]
                if insorted(v2, conflicts)
                    c += 1
                end
            end
        end
    end
    return c
end

function conflict_exists(timed_path1::TimedPath, timed_path2::TimedPath, mapf::MAPF; tol=0)
    return !isnothing(find_conflict(timed_path1, timed_path2, mapf; tol=tol))
end

## Between agents

function find_conflict(a1::Integer, a2::Integer, solution::Solution, mapf::MAPF; tol=0)
    path1, path2 = solution[a1], solution[a2]
    return find_conflict(path1, path2, mapf; tol=tol)
end

function conflict_exists(a1::Integer, a2::Integer, solution::Solution, mapf::MAPF; tol=0)
    path1, path2 = solution[a1], solution[a2]
    return conflict_exists(path1, path2, mapf; tol=tol)
end

function count_conflicts(a1::Integer, a2::Integer, solution::Solution, mapf::MAPF; tol=0)
    path1, path2 = solution[a1], solution[a2]
    return count_conflicts(path1, path2, mapf; tol=tol)
end

## Between one agent and the rest

function find_conflict(a1::Integer, solution::Solution, mapf::MAPF; tol=0)
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

function conflict_exists(a1::Integer, solution::Solution, mapf::MAPF; tol=0)
    return !isnothing(find_conflict(a1, solution, mapf; tol=tol))
end

function count_conflicts(a1::Integer, solution::Solution, mapf::MAPF; tol=0)
    c = 0
    for a2 in 1:nb_agents(mapf)
        if a2 != a1
            c += count_conflicts(a1, a2, solution, mapf; tol=tol)
        end
    end
    return c
end

## In the whole solution

function find_conflict(solution::Solution, mapf::MAPF; tol=0)
    for a1 in 1:nb_agents(mapf), a2 in 1:(a1 - 1)
        conflict = find_conflict(a1, a2, solution, mapf; tol=tol)
        if !isnothing(conflict)
            return conflict
        end
    end
    return nothing
end

function conflict_exists(solution::Solution, mapf::MAPF; tol=0)
    return !isnothing(find_conflict(solution, mapf; tol=tol))
end

function count_conflicts(solution::Solution, mapf::MAPF; tol=0)
    c = 0
    for a1 in 1:nb_agents(mapf), a2 in 1:(a1 - 1)
        c += count_conflicts(a1, a2, solution, mapf; tol=tol)
    end
    return c
end

## Collisions

function colliding_pairs(solution::Solution, mapf::MAPF; tol=0)
    cp = 0
    for a1 in 1:nb_agents(mapf), a2 in 1:(a1 - 1)
        if conflict_exists(a1, a2, solution, mapf; tol=tol)
            cp += 1
        end
    end
    return cp
end

function collision_degree(a1::Integer, solution::Solution, mapf::MAPF; tol=0)
    deg = 0
    for a2 in 1:nb_agents(mapf)
        if conflict_exists(a1, a2, solution, mapf; tol=tol)
            deg += 1
        end
    end
    return deg
end

function collision_degrees(solution::Solution, mapf::MAPF; tol=0)
    return [collision_degree(a1, solution, mapf; tol=tol) for a1 in 1:nb_agents(mapf)]
end
