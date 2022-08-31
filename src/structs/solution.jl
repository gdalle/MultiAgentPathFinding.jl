"""
    Solution = Vector{TimedPath}

Vector of [`TimedPath`](@ref)s, one for each agent of a [`MAPF`](@ref).
"""
const Solution = Vector{TimedPath}

"""
    remove_agents!(solution, agents, mapf)

Remove a set of `agents` from a `solution` and return a back up of their paths.
"""
function remove_agents!(solution::Solution, agents, mapf::MAPF)
    backup = Dict(a => solution[a] for a in agents)
    for a in agents
        solution[a] = TimedPath(mapf.sources[a], Int[])
    end
    return backup
end

## Conflicts

function find_conflict(a1::Integer, a2::Integer, solution::Solution, mapf::MAPF; tol=0)
    return find_conflict(solution[a1], solution[a2], mapf; tol=tol)
end

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

function find_conflict(solution::Solution, mapf::MAPF; tol=0)
    for a1 in 1:nb_agents(mapf), a2 in 1:(a1 - 1)
        conflict = find_conflict(a1, a2, solution, mapf; tol=tol)
        if !isnothing(conflict)
            return conflict
        end
    end
    return nothing
end
