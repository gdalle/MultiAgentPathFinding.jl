function features_edge_agent(
    s::Integer, d::Integer, a::Integer, solution::Solution, mapf::MAPF
)
    timed_path = solution[a]
    (; t0, path) = timed_path
    K = length(path)
    s_belongs_to_path = s in path
    d_belongs_to_path = d in path
    e_belongs_to_path = false
    for k in 1:(K - 1)
        v1, v2 = path[k], path[k + 1]
        if s == v1 && d == v2
            e_belongs_to_path = true
            break
        end
    end
    return (
        Float64(s_belongs_to_path), Float64(d_belongs_to_path), Float64(e_belongs_to_path)
    )
end
