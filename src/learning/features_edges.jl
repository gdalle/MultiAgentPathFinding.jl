function constant_features_edge(s::Integer, d::Integer, mapf::MAPF)
    g = mapf.graph
    outdeg_s = outdegree(g, s)
    indeg_s = indegree(g, s)
    outdeg_d = outdegree(g, d)
    indeg_d = indegree(g, d)
    rev_edge_exists = has_edge(g, d, s)
    return Float64[outdeg_s, outdeg_d, rev_edge_exists]
end

function solution_features_edge(s::Integer, d::Integer, solution::Solution, mapf::MAPF)
    g = mapf.graph
    paths_crossing_s = 0
    paths_crossing_d = 0
    paths_crossing_e = 0
    for path in solution
        for ((t1, v1), (t2, v2)) in zip(path[1:(end - 1)], path[2:end])
            paths_crossing_s += (v1 == s) + (v2 == s)
            paths_crossing_d += (v1 == d) + (v2 == d)
            paths_crossing_e += (v1 == s && v2 == d)
        end
    end
    return Float64[paths_crossing_s, paths_crossing_d]
end

function all_features_edge(s::Integer, d::Integer, solution::Solution, mapf::MAPF)
    return vcat(
        constant_features_edge(s, d, mapf), solution_features_edge(s, d, solution, mapf)
    )
end

function edges_embedding(mapf::MAPF)
    solution = independent_astar(mapf)
    x = reduce(
        hcat,
        all_features_edge(src(ed), dst(ed), solution, mapf) for ed in edges(mapf.graph)
    )
    s = std(x; dims=2)
    s[isapprox.(s, 0.0)] .= 1  # columns with zero variance
    x = (x .- mean(x; dims=2)) ./ s
    return x
end
