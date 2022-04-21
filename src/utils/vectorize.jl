function path_to_vec(path::Path, mapf::MAPF; T=nothing)
    g = mapf.graph
    V, E = nv(g), ne(g)
    if isnothing(T)
        inds = Int[]
        for ((_, v1), (_, v2)) in zip(path[1:end-1], path[2:end])
            for (e, ed) in enumerate(edges(g))
                if v1 == src(ed) && v2 == dst(ed)
                    push!(inds, e)
                end
            end
        end
        vals = ones(Float64, length(inds))
        return sparsevec(inds, vals, E)
    else
        inds = [(t-1) * V + v for (t, v) in path]
        vals = ones(Float64, length(inds))
        return sparsevec(inds, vals, T * V)
    end
end

function solution_to_vec(solution::Solution, mapf::MAPF; T=nothing)
    return reduce(vcat, path_to_vec(path, mapf; T=T) for path in solution)
end
