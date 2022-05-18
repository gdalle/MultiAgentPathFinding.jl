## Between vertices / edges

function conflicting_vertices(v1::Integer, v2::Integer, mapf::MAPF)
    for g1 in mapf.vertex_group_memberships[v1]
        if insorted(v2, mapf.vertex_groups[g1])
            return true
        end
    end
    return false
end

function conflicting_edges((u1, v1)::NTuple{2,<:Integer}, (u2, v2)::NTuple{2,<:Integer}, mapf::MAPF)
    e1 = mapf.edge_indices[u1, v1]
    e2 = mapf.edge_indices[u2, v2]
    for g1 in mapf.edge_group_memberships[e1]
        if insorted(e2, mapf.edge_groups[g1])
            return true
        end
    end
    return false
end

## Between paths

function find_conflict(path1::Path, path2::Path, mapf::MAPF; tol=0)
    for (t1, v1) in path1
        for (t2, v2) in path2
            if (abs(t1 - t2) <= tol) && conflicting_vertices(v1, v2, mapf)
                return (t1, v1), (t2, v2)
            end
        end
    end
    return nothing
end

function conflict_exists(path1::Path, path2::Path, mapf::MAPF; tol=0)
    return !isnothing(find_conflict(path1, path2, mapf; tol=tol))
end

function count_conflicts(path1::Path, path2::Path, mapf::MAPF; tol=0)
    c = 0
    for (t1, v1) in path1, (t2, v2) in path2
        if (abs(t1 - t2) <= tol) && conflicting_vertices(v1, v2, mapf)
            c += 1
        end
    end
    return c
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
    for a2 = 1:nb_agents(mapf)
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
    for a2 = 1:nb_agents(mapf)
        if a2 != a1
            c += count_conflicts(a1, a2, solution, mapf; tol=tol)
        end
    end
    return c
end

## In the whole solution

function find_conflict(solution::Solution, mapf::MAPF; tol=0)
    for a1 = 1:nb_agents(mapf), a2 = 1:a1-1
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
    for a1 = 1:nb_agents(mapf), a2 = 1:a1-1
        c += count_conflicts(a1, a2, solution, mapf; tol=tol)
    end
    return c
end

## Collisions

function colliding_pairs(solution::Solution, mapf::MAPF; tol=0)
    cp = 0
    for a1 = 1:nb_agents(mapf), a2 = 1:a1-1
        if conflict_exists(a1, a2, solution, mapf; tol=tol)
            cp += 1
        end
    end
    return cp
end

function collision_degree(a1::Integer, solution::Solution, mapf::MAPF; tol=0)
    deg = 0
    for a2 = 1:nb_agents(mapf)
        if conflict_exists(a1, a2, solution, mapf; tol=tol)
            deg += 1
        end
    end
    return deg
end

function collision_degrees(solution::Solution, mapf::MAPF; tol=0)
    return [collision_degree(a1, solution, mapf; tol=tol) for a1 = 1:nb_agents(mapf)]
end
