function has_empty_paths(solution::Solution)
    return any(length(path) == 0 for path in solution)
end

function is_feasible(solution::Solution, mapf::MAPF)
    g = mapf.graph
    for a in 1:nb_agents(mapf)
        s = mapf.sources[a]
        d = mapf.destinations[a]
        t0 = mapf.starting_times[a]
        timed_path = solution[a]
        path = timed_path.path
        if length(path) == 0
            return false  # empty path
        elseif timed_path.t0 != t0
            return false  # wrong starting time
        elseif first(path) != s
            return false  # wrong source
        elseif last(path) != d
            return false  # wrong destination
        else
            for k in 1:(length(path) - 1)
                v1, v2 = path[k], path[k + 1]
                if !has_edge(g, v1, v2)
                    return false  # invalid edge
                end
            end
        end
    end
    if conflict_exists(solution, mapf)
        return false
    else
        return true
    end
end

is_feasible(::Nothing, ::MAPF; kwargs...) = false
