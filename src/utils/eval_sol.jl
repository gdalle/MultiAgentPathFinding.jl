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
    return !conflict_exists(solution, mapf)
end

function path_weight(path::Path, mapf::MAPF; edge_weights=mapf.edge_weights)
    edge_indices = mapf.edge_indices
    c = 0.
    for k in 1:(length(path) - 1)
        (_, v1), (_, v2) = path[k], path[k + 1]
        c += edge_weights[edge_indices[v1, v2]]
    end
    return c
end

function flowtime(solution::Solution, mapf::MAPF; edge_weights=mapf.edge_weights)
    return sum(path_weight(path, mapf; edge_weights=edge_weights) for path in solution)
end

is_feasible(::Nothing, ::MAPF; kwargs...) = false
flowtime(::Nothing, ::MAPF; kwargs...) = Inf

max_time(path::Path) = maximum(t for (t, v) in path)
max_time(solution::Solution) = maximum(max_time(path) for path in solution)
