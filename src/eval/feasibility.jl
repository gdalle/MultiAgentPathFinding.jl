"""
    is_feasible(solution, mapf)
"""
function is_feasible(solution::Solution, mapf::MAPF)
    (; g, departures, arrivals, departure_times, max_arrival_times) = mapf
    for a in 1:nb_agents(mapf)
        timed_path = solution[a]
        if length(timed_path) == 0
            return false  # empty path
        elseif departure_time(timed_path) != departure_times[a]
            @warn "Wrong departure time for agent $a"
            return false  # wrong departure time
        elseif arrival_time(timed_path) > max_arrival_times[a]
            @warn "Late arrival time for agent $a"
            return false  # late arrival time
        elseif first_vertex(timed_path) != departures[a]
            @warn "Wrong departure vertex for agent $a"
            return false  # wrong departure vertex
        elseif last_vertex(timed_path) != arrivals[a]
            @warn "Wrong arrival vertex for agent $a"
            return false  # wrong arrival vertex
        elseif !exists_in_graph(timed_path, g)
            @warn "Path of agent $a does not exist in graph"
            return false  # invalid vertices or edges
        end
    end
    if find_conflict(solution, mapf) !== nothing
        return false
    else
        return true
    end
end

is_feasible(::Nothing, ::MAPF; kwargs...) = false
