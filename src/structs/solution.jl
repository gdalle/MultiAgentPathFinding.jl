"""
    Solution = Vector{TimedPath}

Vector of `TimedPath`s, one for each agent of a `MAPF`.
"""
const Solution = Vector{TimedPath}

"""
$(TYPEDSIGNATURES)

Return a vector of empty `TimedPath`s.
"""
function empty_solution(mapf::MAPF)
    return [TimedPath(mapf.departure_times[a], Int[]) for a in 1:nb_agents(mapf)]
end

"""
$(TYPEDSIGNATURES)

Check that all paths in a solution are non empty.
"""
function all_non_empty(solution::Solution)
    return all(length(timed_path) > 0 for timed_path in solution)
end

"""
$(TYPEDSIGNATURES)

Remove a set of agents from a solution and return a back up of their paths.
"""
function remove_agents!(solution::Solution, agents::AbstractVector{<:Integer}, mapf::MAPF)
    backup = Dict(a => solution[a] for a in agents)
    for a in agents
        solution[a] = TimedPath(mapf.departures[a], Int[])
    end
    return backup
end

## Cost

"""
$(TYPEDSIGNATURES)

Sum the weight of all the paths in a solution.
"""
function total_path_cost(solution::Solution, mapf::MAPF)
    return sum(path_cost(timed_path, mapf) for timed_path in solution)
end

"""
$(TYPEDSIGNATURES)

Compute the maximum arrival time of all the paths in a solution.
"""
makespan(solution::Solution) = maximum(arrival_time(timed_path) for timed_path in solution)

"""
$(TYPEDSIGNATURES)

Check whether a solution is feasible when agents are considered separately.
"""
function is_individually_feasible(solution::Solution, mapf::MAPF; verbose=false)
    for a in 1:nb_agents(mapf)
        timed_path = solution[a]
        if isempty(timed_path)
            verbose && @warn "Empty path for agent $a"
            return false  # empty path
        elseif departure_time(timed_path) != mapf.departure_times[a]
            verbose && @warn "Wrong departure time for agent $a"
            return false  # wrong departure time
        elseif departure_vertex(timed_path) != mapf.departures[a]
            verbose && @warn "Wrong departure vertex for agent $a"
            return false  # wrong departure vertex
        elseif arrival_vertex(timed_path) != mapf.arrivals[a]
            verbose && @warn "Wrong arrival vertex for agent $a"
            return false  # wrong arrival vertex
        elseif !exists_in_graph(timed_path, mapf.g)
            verbose && @warn "Path of agent $a does not exist in graph"
            return false  # invalid vertices or edges
        end
    end
    return true
end

"""
$(TYPEDSIGNATURES)

Check whether a solution contains any conflicts between agents.
"""
function is_collectively_feasible(solution::Solution, mapf::MAPF; verbose=false)
    conflict = find_conflict(solution, mapf)
    if conflict !== nothing
        verbose && @warn "$conflict in solution"
        return false
    else
        return true
    end
end

"""
$(TYPEDSIGNATURES)

Check whether a solution is both individually and collectively feasible (correct paths and no conflicts).
"""
function is_feasible(solution::Solution, mapf::MAPF; verbose=false)
    return is_individually_feasible(solution, mapf; verbose) &&
           is_collectively_feasible(solution, mapf; verbose)
end
