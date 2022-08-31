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

function solution_to_mat(solution::Solution, mapf::MAPF)
    (; g, edge_indices) = mapf
    V, E = nv(g), ne(g)
    A = nb_agents(mapf)
    I = Int[]
    J = Int[]
    val = Float64[]
    for a in 1:A
        timed_path = solution[a]
        (; path) = timed_path
        K = length(path)
        for k in 1:(K - 1)
            v1, v2 = path[k], path[k + 1]
            e = edge_indices[v1, v2]
            push!(I, e)
            push!(J, a)
            push!(val, 1.0)
        end
    end
    return sparse(I, J, val, E, A)
end
