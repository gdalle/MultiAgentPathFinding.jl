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

flowtime(::Nothing, ::MAPF; kwargs...) = Inf

max_time(path::Path) = maximum(t for (t, v) in path)
max_time(solution::Solution) = maximum(max_time(path) for path in solution)
