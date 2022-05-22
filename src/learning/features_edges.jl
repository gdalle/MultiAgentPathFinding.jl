function constant_features_edge(s::Integer, d::Integer, mapf::MAPF)
    g = mapf.graph
    e = mapf.edge_indices[s, d]
    edge_weight = mapf.edge_weights_vec[e]
    indeg_s = indegree(g, s)
    outdeg_s = outdegree(g, s)
    indeg_d = indegree(g, d)
    outdeg_d = outdegree(g, d)
    s_is_source = s in mapf.sources
    d_is_source = d in mapf.sources
    s_is_destination = s in mapf.destinations
    d_is_destination = d in mapf.destinations
    return Float64[
        edge_weight,
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
    g = mapf.graph
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
    s_belongs_to_path = false
    d_belongs_to_path = false
    edge_belongs_to_path = false
    timed_path = solution[a]
    (; t0, path) = timed_path
    K = length(path)
    for k in 1:(K - 1)
        v1, v2 = path[k], path[k + 1]
        if s in (v1, v2)
            s_belongs_to_path = true
        end
        if d in (v1, v2)
            d_belongs_to_path = true
        end
        if s in (v1, v2) && d in (v1, v2)
            edge_belongs_to_path = true
        end
    end
    return Float64[s_belongs_to_path, d_belongs_to_path, edge_belongs_to_path]
end

function edge_embedding(s::Integer, d::Integer, solution::Solution, mapf::MAPF)
    return vcat(
        constant_features_edge(s, d, mapf), solution_features_edge(s, d, solution, mapf)
    )
end

function edge_embedding(s::Integer, d::Integer, a::Integer, solution::Solution, mapf::MAPF)
    return vcat(
        edge_embedding(s, d, solution, mapf), agent_features_edge(s, d, a, solution, mapf)
    )
end

function all_edges_embedding(solution::Solution, mapf::MAPF)
    x = reduce(
        hcat, edge_embedding(src(ed), dst(ed), solution, mapf) for ed in edges(mapf.graph)
    )
    return x
end

function all_edges_embedding(a::Integer, solution::Solution, mapf::MAPF)
    x = reduce(
        hcat,
        edge_embedding(src(ed), dst(ed), a, solution, mapf) for ed in edges(mapf.graph)
    )
    return x
end
