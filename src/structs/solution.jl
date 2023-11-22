"""
    Solution = Vector{TimedPath}

Vector of `TimedPath`s, one for each agent of a `MAPF`.
"""
const Solution = Vector{TimedPath}

"""
    empty_solution(mapf)

Return a vector of empty `TimedPath`s.
"""
function empty_solution(mapf::MAPF)
    return [TimedPath(mapf.departure_times[a], Int[]) for a in 1:nb_agents(mapf)]
end

"""
    all_non_empty(solution)

Check that all paths in a `Solution` are non empty.
"""
function all_non_empty(solution::Solution)
    return all(length(timed_path) > 0 for timed_path in solution)
end

"""
    remove_agents!(solution, agents, mapf)

Remove a set of agents from a `Solution` and return a back up of their paths.
"""
function remove_agents!(solution::Solution, agents, mapf::MAPF)
    backup = Dict(a => solution[a] for a in agents)
    for a in agents
        solution[a] = TimedPath(mapf.departures[a], Int[])
    end
    return backup
end

## Cost

"""
    flowtime(solution, mapf)

Sum the flowtime of all the `TimedPath`s in a `Solution`.
"""
function flowtime(solution::Solution, mapf::MAPF)
    return sum(path_weight(timed_path, mapf) for timed_path in solution)
end

"""
    makespan(solution)

Compute the maximum arrival time of all the `TimedPath`s in a `Solution`.
"""
makespan(solution::Solution) = maximum(arrival_time(timed_path) for timed_path in solution)

"""
    is_individually_feasible(solution, mapf[; verbose])

Check whether a `Solution` is feasible when agents are considered separately.
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
    is_collectively_feasible(solution, mapf[; verbose])

Check whether a `Solution` contains any conflicts between agents.
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
    is_feasible(solution, mapf[; verbose])

Check whether a `Solution` is both individually and collectively feasible.
"""
function is_feasible(solution::Solution, mapf::MAPF; verbose=false)
    return is_individually_feasible(solution, mapf; verbose) &&
           is_collectively_feasible(solution, mapf; verbose)
end
