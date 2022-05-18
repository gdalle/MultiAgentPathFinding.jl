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
            @warn "Empty path"
            return false
        elseif path[1] != (t0, s)
            @warn "Wrong beginning"
            return false
        elseif path[end][2] != d
            @warn "Wrong end"
            return false
        else
            for k in 1:(length(path) - 1)
                (t1, v1), (t2, v2) = path[k], path[k + 1]
                if t2 != t1 + 1
                    @warn "Temporal jump"
                    return false
                elseif !has_edge(g, v1, v2)
                    @warn "Fake edge"
                    return false
                end
            end
        end
    end
    if conflict_exists(solution, mapf)
        @warn "Conflict"
        return false
    else
        return true
    end
end

is_feasible(::Nothing, ::MAPF; kwargs...) = false
