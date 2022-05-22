"""
    TimedPath

Timed path through a graph.
"""
struct TimedPath
    t0::Int
    path::Vector{Int}
end

Base.length(timed_path::TimedPath) = length(timed_path.path)

function path_to_vec(timed_path::TimedPath, mapf::MAPF)
    g = mapf.graph
    path = timed_path.path
    edge_indices = mapf.edge_indices
    K = length(path)
    y = zeros(Int, ne(g))
    for k in 1:(K - 1)
        _, v1 = path[k]
        _, v2 = path[k + 1]
        e = edge_indices[v1, v2]
        y[e] += 1
    end
    return y
end
