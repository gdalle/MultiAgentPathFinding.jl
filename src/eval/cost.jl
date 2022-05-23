"""
    path_weight(timed_path, mapf[, edge_weights_vec])
"""
function path_weight(
    timed_path::TimedPath,
    mapf::MAPF,
    edge_weights_vec::AbstractVector{W}=mapf.edge_weights_vec,
) where {W}
    (; path) = timed_path
    (; edge_indices) = mapf
    c = zero(W)
    for k in 1:(length(path) - 1)
        v1, v2 = path[k], path[k + 1]
        e = edge_indices[v1, v2]
        c += edge_weights_vec[e]
    end
    return c
end

"""
    flowtime(solution, mapf[, edge_weights_vec])
"""
function flowtime(
    solution::Solution, mapf::MAPF, edge_weights_vec::AbstractVector=mapf.edge_weights_vec
)
    return sum(path_weight(timed_path, mapf, edge_weights_vec) for timed_path in solution)
end

flowtime(::Nothing, ::MAPF; kwargs...) = Inf

max_time(timed_path::TimedPath) = timed_path.t0 + length(timed_path.path) - 1

"""
    max_time(solution)
"""
max_time(solution::Solution) = maximum(max_time(timed_path) for timed_path in solution)
