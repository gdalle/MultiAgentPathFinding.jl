"""
    Path

Vector of tuples `(t,v)` corresponding to a timed path through a graph.
"""
const Path = Vector{Tuple{Int,Int}}

"""
    Solution

Vector of `Path`s, one for each agent of a [`MAPF`](@ref).
"""
const Solution = Vector{Path}

function path_to_vec(path::Path, mapf::MAPF)
    g = mapf.graph
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

function path_to_vec_sparse(path::Path, mapf::MAPF)
    g = mapf.graph
    edge_indices = mapf.edge_indices
    V, E = nv(g), ne(g)
    K = length(path)
    ind = Int[]
    val = Int[]
    for k in 1:(K - 1)
        _, v1 = path[k]
        _, v2 = path[k + 1]
        e = edge_indices[v1, v2]
        i = findfirst(isequal(e), ind)
        if isnothing(i)
            push!(ind, e)
            push!(val, 1)
        else
            val[i] += 1
        end
    end
    return sparsevec(ind, val, E)
end

function solution_to_mat(solution::Solution, mapf::MAPF)
    g = mapf.graph
    edge_indices = mapf.edge_indices
    V, E = nv(g), ne(g)
    A = nb_agents(mapf)
    I = Int[]
    J = Int[]
    val = Float64[]
    for a in 1:A
        path = solution[a]
        K = length(path)
        for k in 1:(K - 1)
            _, v1 = path[k]
            _, v2 = path[k + 1]
            e = edge_indices[v1, v2]
            push!(I, e)
            push!(J, a)
            push!(val, 1.)
        end
    end
    return sparse(I, J, val, E, A)
end

function solution_to_mat2(solution::Solution, mapf::MAPF)
    E = ne(mapf.graph)
    A = nb_agents(mapf)
    path_vecs = [path_to_vec(solution[a], mapf) for a in 1:A]
    rowval = reduce(vcat, pv.nzind for pv in path_vecs)
    nzval = reduce(vcat, pv.nzval for pv in path_vecs)
    colptr = reduce(vcat, fill(a, length(pv.nzval)) for (a, pv) in enumerate(path_vecs))
    return SparseMatrixCSC(E, A, colptr, rowval, nzval)
end
