function path_to_vec(path::Path, mapf::MAPF; T::Integer)
    g = mapf.graph
    @assert is_directed(g)
    @assert T >= maximum(t for (t, v) in path)
    V = nv(g)
    inds = [(t-1) * V + v for (t, v) in path]
    vals = ones(Float64, length(path))
    return sparsevec(inds, vals, T * V)
end

function solution_to_vec(solution::Solution, mapf::MAPF; T::Integer)
    return reduce(vcat, path_to_vec(path, mapf; T=T) for path in solution)
end
