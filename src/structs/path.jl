"""
    TimedPath

Temporal path through a graph.

# Fields
- `t0::Int`
- `path::Vector{Int}`
"""
struct TimedPath
    t0::Int
    path::Vector{Int}
end

Base.length(timed_path::TimedPath) = length(timed_path.path)

"""
    path_to_vec(timed_path, mapf)

Encode a `timed_path` as a dense integer vector that counts edge crossings.
"""
function path_to_vec(timed_path::TimedPath, mapf::MAPF)
    (; g, edge_indices) = mapf
    (; path) = timed_path
    K = length(path)
    y = zeros(Int, ne(g))
    for k in 1:(K - 1)
        v1, v2 = path[k], path[k + 1]
        e = edge_indices[v1, v2]
        y[e] += 1
    end
    return y
end

"""
    path_to_vec_sparse(timed_path, mapf)

Encode a `timed_path` as a sparse integer vector that counts edge crossings.
"""
function path_to_vec_sparse(timed_path::TimedPath, mapf::MAPF)
    (; g, edge_indices) = mapf
    (; path) = timed_path
    K = length(path)
    I = Vector{Int}(undef, K - 1)
    V = Vector{Int}(undef, K - 1)
    for k in 1:(K - 1)
        v1, v2 = path[k], path[k + 1]
        e = edge_indices[v1, v2]
        I[k] = e
        V[k] = 1
    end
    return sparsevec(I, V, ne(g))
end
