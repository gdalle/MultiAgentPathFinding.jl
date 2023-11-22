"""
$(TYPEDEF)

Store a conflict between two agents for debugging purposes.

# Fields

$(TYPEDFIELDS)
"""
struct Conflict
    "type of conflict (`:vertex` or `:vdge`)"
    name::Symbol
    "first agent"
    a1::Int
    "second agent"
    a2::Int
    "time for the first agent"
    t1::Int
    "time for the second agent"
    t2::Int
    "vertex for the first agent"
    u1::Int
    "vertex for the second agent"
    u2::Int
end

## Find conflicts

"""
    find_conflict(solution, mapf[; tol=0])

Find a conflict in a solution.
"""
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

"""
    count_conflicts(solution, mapf[; tol=0])

Count the number of conflicts in a solution.
"""
function count_conflicts(solution::Solution, mapf::MAPF; tol=0)
    c = 0
    for a1 in 1:nb_agents(mapf)
        for a2 in 1:(a1 - 1)
            c += count_conflicts(a1, a2, solution, mapf; tol=tol)
        end
    end
    return c
end

"""
    find_conflict(a1, a2, solution, mapf[; tol=0])

Find a conflict between agents `a1` and `a2` in a solution.
"""
function find_conflict(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    vc = find_vertex_conflict(a1, a2, solution, mapf; tol=tol)
    !isnothing(vc) && return vc
    ec = find_edge_conflict(a1, a2, solution, mapf; tol=tol)
    !isnothing(ec) && return ec
    return nothing
end

"""
    count_conflicts(a1, a2, solution, mapf[; tol=0])

Count the number of conflicts between agents `a1` and `a2` in a solution.
"""
function count_conflicts(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    vcc = count_vertex_conflicts(a1, a2, solution, mapf; tol=tol)
    ecc = count_edge_conflicts(a1, a2, solution, mapf; tol=tol)
    return vcc + ecc
end

"""
    find_vertex_conflict(a1, a2, solution, mapf[; tol=0])

Find an occurrence where the paths of `a1` and `a2` in the solution visit incompatible vertices less than `tol` time steps apart.

Return either a [`Conflict`](@ref) object or `nothing`.
"""
function find_vertex_conflict(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    timed_path1 = solution[a1]
    timed_path2 = solution[a2]
    for t1 in departure_time(timed_path1):arrival_time(timed_path1)
        u1 = vertex_at_time(timed_path1, t1)
        u1_conflicts = mapf.vertex_conflicts[u1]
        for t2 in (
            ((t1 - tol):(t1 + tol)) ∩
            (departure_time(timed_path2):arrival_time(timed_path2))
        )
            u2 = vertex_at_time(timed_path2, t2)
            exists = u2 in u1_conflicts
            exists && return Conflict(:vertex, a1, a2, t1, t2, u1, u2)
        end
    end
    return nothing
end

"""
    count_vertex_conflicts(a1, a2, solution, mapf[; tol=0])

Count the number of occurrences where the paths of `a1` and `a2` in the solution visit incompatible vertices less than `tol` time steps apart.
"""
function count_vertex_conflicts(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    c = 0
    timed_path1 = solution[a1]
    timed_path2 = solution[a2]
    for t1 in departure_time(timed_path1):arrival_time(timed_path1)
        u1 = vertex_at_time(timed_path1, t1)
        u1_conflicts = mapf.vertex_conflicts[u1]
        for t2 in (
            ((t1 - tol):(t1 + tol)) ∩
            (departure_time(timed_path2):arrival_time(timed_path2))
        )
            u2 = vertex_at_time(timed_path2, t2)
            exists = u2 in u1_conflicts
            c += exists
        end
    end
    return c
end

"""
    find_edge_conflict(a1, a2, solution, mapf[; tol=0])

Find an occurrence where the paths of `a1` and `a2` in the solution cross incompatible edges less than `tol` time steps apart.

Return either a [`Conflict`](@ref) object or `nothing`.
"""
function find_edge_conflict(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    timed_path1 = solution[a1]
    timed_path2 = solution[a2]
    for t1 in departure_time(timed_path1):(arrival_time(timed_path1) - 1)
        u1v1 = edge_at_time(timed_path1, t1)
        u1v1_conflicts = mapf.edge_conflicts[u1v1]
        for t2 in (
            ((t1 - tol):(t1 + tol)) ∩
            (departure_time(timed_path2):(arrival_time(timed_path2) - 1))
        )
            u2v2 = edge_at_time(timed_path2, t2)
            exists = u2v2 in u1v1_conflicts
            exists && return Conflict(:edge, a1, a2, t1, t2, u1v1...)
        end
    end
    return nothing
end

"""
    count_edge_conflicts(a1, a2, solution, mapf[; tol=0])

Count the number of occurrences where the paths of `a1` and `a2` in the solution cross incompatible edges less than `tol` time steps apart.
"""
function count_edge_conflicts(a1, a2, solution::Solution, mapf::MAPF; tol=0)
    c = 0
    timed_path1 = solution[a1]
    timed_path2 = solution[a2]
    for t1 in departure_time(timed_path1):(arrival_time(timed_path1) - 1)
        u1v1 = edge_at_time(timed_path1, t1)
        u1v1_conflicts = mapf.edge_conflicts[u1v1]
        for t2 in (
            ((t1 - tol):(t1 + tol)) ∩
            (departure_time(timed_path2):(arrival_time(timed_path2) - 1))
        )
            u2v2 = edge_at_time(timed_path2, t2)
            exists = u2v2 in u1v1_conflicts
            c += exists
        end
    end
    return c
end
