"""
$(TYPEDEF)

Store one [`TimedPath`](@ref) for each agent of a [`MAPF`](@ref).

# Fields

$(TYPEDFIELDS)
"""
struct Solution
    timed_paths::Dict{Int,TimedPath}
end

"""
$(TYPEDSIGNATURES)

Construct an empty `Solution` with no agents.
"""
Solution() = Solution(Dict{Int,TimedPath}())

"""
$(TYPEDSIGNATURES)

Remove a set of agents from `solution` and return a `backup_solution` containing only them.
"""
function remove_agents!(solution::Solution, agents::AbstractVector{<:Integer})
    backup_solution = Solution(Dict(a => solution.timed_paths[a] for a in agents))
    for a in agents
        delete!(solution.timed_paths, a)
    end
    return backup_solution
end

"""
$(TYPEDSIGNATURES)

Reinsert the set of agents from `backup_solution` into `solution`.
"""
function reinsert_agents!(solution::Solution, backup_solution::Solution)
    for a in keys(backup_solution.timed_paths)
        solution.timed_paths[a] = backup_solution.timed_paths[a]
    end
    return backup_solution
end

## Cost

"""
$(TYPEDSIGNATURES)

Sum the costs of all the paths in `solution`.
Costs are computed within `mapf` for each agent.
"""
function solution_cost(solution::Solution, mapf::MAPF)
    return sum(
        path_cost(timed_path, a, mapf) for (a, timed_path) in pairs(solution.timed_paths)
    )
end
