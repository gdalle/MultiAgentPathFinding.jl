function has_empty_paths(solution::Solution)
    return any(length(path) == 0 for path in solution)
end

function is_feasible(solution::Solution, mapf::MAPF)
    g = mapf.graph
    for a in 1:nb_agents(mapf)
        s = mapf.sources[a]
        d = mapf.destinations[a]
        t0 = mapf.starting_times[a]
        path = solution[a]
        if length(path) == 0
            return false
        elseif path[1] != (t0, s)
            return false
        elseif path[end][2] != d
            return false
        else
            for k in 1:(length(path) - 1)
                (t1, v1), (t2, v2) = path[k], path[k + 1]
                if t2 != t1 + 1
                    return false
                elseif !has_edge(g, v1, v2)
                    return false
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
