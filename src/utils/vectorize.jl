function path_to_vec(path::Path, mapf::MAPF; T=nothing)
    g = mapf.graph
    edge_indices = mapf.edge_indices
    V, E = nv(g), ne(g)
    K = length(path)
    if isnothing(T)
        ind = Int[]
        val = Float64[]
        for k in 1:(K - 1)
            _, v1 = path[k]
            _, v2 = path[k + 1]
            e = edge_indices[(v1, v2)]
            i = findfirst(isequal(e), ind)
            if isnothing(i)
                push!(ind, e)
                push!(val, 1.)
            else
                val[i] += 1.
            end
        end
        return sparsevec(ind, val, E)
    else
        ind = Vector{Int}(undef, K - 1)
        for k in 1:(K - 1)
            t, v1 = path[k]
            _, v2 = path[k + 1]
            e = edge_indices[(v1, v2)]
            ind[k] = (t - 1) * E + e
        end
        val = ones(Float64, K - 1)
        return sparsevec(ind, val, T * E)
    end
end

function solution_to_mat(solution::Solution, mapf::MAPF; T=nothing)
    return reduce(hcat, path_to_vec(solution[a], mapf; T=T) for a in 1:nb_agents(mapf))
end

function solution_to_mat2(solution::Solution, mapf::MAPF; T=nothing)
    E = ne(mapf.graph)
    A = nb_agents(mapf)
    m = T * E
    n = A
    path_vecs = [path_to_vec(solution[a], mapf; T=T) for a in 1:A]
    rowval = reduce(vcat, pv.nzind for pv in path_vecs)
    nzval = reduce(vcat, pv.nzval for pv in path_vecs)
    colptr = reduce(vcat, fill(a, length(pv.nzval)) for (a, pv) in enumerate(path_vecs))
    return SparseMatrixCSC(m, n, colptr, rowval, nzval)
end
