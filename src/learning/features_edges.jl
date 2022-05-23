function constant_features_edge(s::Integer, d::Integer, mapf::MAPF)
    (; g, edge_indices, edge_weights_vec, sources, destinations) = mapf
    e = edge_indices[s, d]
    w = edge_weights_vec[e]
    indeg_s = indegree(g, s)
    outdeg_s = outdegree(g, s)
    indeg_d = indegree(g, d)
    outdeg_d = outdegree(g, d)
    s_is_source = s in sources
    d_is_source = d in sources
    s_is_destination = s in destinations
    d_is_destination = d in destinations
    return Float64[
        w,
        indeg_s,
        outdeg_s,
        indeg_d,
        outdeg_d,
        s_is_source,
        d_is_source,
        s_is_destination,
        d_is_destination,
    ]
end

function solution_features_edge(s::Integer, d::Integer, solution::Solution, mapf::MAPF)
    (; g) = mapf
    paths_visiting_s = 0
    paths_visiting_d = 0
    paths_crossing_e = 0
    paths_crossing_e_rev = 0
    for timed_path in solution
        (; t0, path) = timed_path
        K = length(path)
        for k in 1:(K - 1)
            v1, v2 = path[k], path[k + 1]
            paths_visiting_s += (v1 == s) + (v2 == s)
            paths_visiting_d += (v1 == d) + (v2 == d)
            paths_crossing_e += (v1 == s && v2 == d)
            paths_crossing_e_rev += (v1 == d && v2 == s)
        end
    end
    return Float64[
        paths_visiting_s, paths_visiting_d, paths_crossing_e, paths_crossing_e_rev
    ]
end

function agent_features_edge(
    s::Integer, d::Integer, a::Integer, solution::Solution, mapf::MAPF
)
    timed_path = solution[a]
    (; t0, path) = timed_path
    s_belongs_to_path = s in path
    d_belongs_to_path = d in path
    edge_belongs_to_path = false
    K = length(path)
    for (v1, v2) in zip(view(path, 1:K-1), view(path, 2:K))
        if s == v1 && d == v2
            edge_belongs_to_path = true
            break
        end
    end
    return Float64[s_belongs_to_path, d_belongs_to_path, edge_belongs_to_path]
end

function edge_embedding(s::Integer, d::Integer, a::Integer, solution::Solution, mapf::MAPF)
    f1 = constant_features_edge(s, d, mapf)
    f2 = solution_features_edge(s, d, solution, mapf)
    f3 = agent_features_edge(s, d, a, solution, mapf)
    return vcat(f1, f2, f3)
end

function all_edges_embedding(a::Integer, solution::Solution, mapf::MAPF)
    (; g) = mapf
    ed = first(edges(g))
    E = ne(g)
    F = length(edge_embedding(src(ed), dst(ed), a, solution, mapf))
    x = Matrix{Float64}(undef, F, E)
    for (e, ed) in enumerate(edges(g))
        x[:, e] .= edge_embedding(src(ed), dst(ed), a, solution, mapf)
    end
    return x
end
