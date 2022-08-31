"""
    is_feasible(solution, mapf)
"""
function is_feasible(solution::Solution, mapf::MAPF)
    (; g, sources, destinations, departure_times, max_arrival_times) = mapf
    for a in 1:nb_agents(mapf)
        timed_path = solution[a]
        if length(timed_path) == 0
            return false  # empty path
        elseif departure_time(timed_path) != departure_times[a]
            return false  # wrong starting time
        elseif arrival_time(timed_path) > max_arrival_times[a]
            return false  # late arrival
        elseif first_vertex(timed_path) != sources[a]
            return false  # wrong source
        elseif last_vertex(timed_path) != destinations[a]
            return false  # wrong destination
        elseif !exists_in_graph(timed_path, g)
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
