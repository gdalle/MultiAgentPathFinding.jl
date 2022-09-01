"""
    Solution = Vector{TimedPath}

Vector of [`TimedPath`](@ref)s, one for each agent of a [`MAPF`](@ref).
"""
const Solution = Vector{TimedPath}

function empty_solution(mapf::MAPF)
    return [TimedPath(mapf.departure_times[a], Int[]) for a in 1:nb_agents(mapf)]
end

function all_non_empty(solution::Solution)
    return all(length(timed_path) > 0 for timed_path in solution)
end

"""
    remove_agents!(solution, agents, mapf)

Remove a set of `agents` from a `solution` and return a back up of their paths.
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
    flowtime(solution, mapf[, edge_weights_vec])
"""
function flowtime(solution::Solution, mapf::MAPF, edge_weights_vec=mapf.edge_weights_vec)
    return sum(flowtime(timed_path, mapf, edge_weights_vec) for timed_path in solution)
end

"""
    max_time(solution)
    """
max_time(solution::Solution) = maximum(arrival_time(timed_path) for timed_path in solution)

flowtime(::Nothing, ::MAPF{W}; kwargs...) where {W} = typemax(W)

## Conflicts

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

"""
is_feasible(solution, mapf)
"""
function is_feasible(solution::Solution, mapf::MAPF; verbose=false)
    (; g, departures, arrivals, departure_times, max_arrival_times) = mapf
    for a in 1:nb_agents(mapf)
        timed_path = solution[a]
        if length(timed_path) == 0
            verbose && @warn "Empty path for agent $a"
            return false  # empty path
        elseif departure_time(timed_path) != departure_times[a]
            verbose && @warn "Wrong departure time for agent $a"
            return false  # wrong departure time
        elseif (
            (max_arrival_times[a] !== nothing) &&
            (arrival_time(timed_path) > max_arrival_times[a])
        )
            verbose && @warn "Late arrival time for agent $a"
            return false  # late arrival time
        elseif first_vertex(timed_path) != departures[a]
            verbose && @warn "Wrong departure vertex for agent $a"
            return false  # wrong departure vertex
        elseif last_vertex(timed_path) != arrivals[a]
            verbose && @warn "Wrong arrival vertex for agent $a"
            return false  # wrong arrival vertex
        elseif !exists_in_graph(timed_path, g)
            verbose && @warn "Path of agent $a does not exist in graph"
            return false  # invalid vertices or edges
        end
    end
    if find_conflict(solution, mapf) !== nothing
        verbose && @warn "Conflict in solution"
        return false
    else
        return true
    end
end

is_feasible(::Nothing, ::MAPF; kwargs...) = false
