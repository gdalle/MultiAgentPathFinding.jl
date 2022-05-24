function graph_features_edge(s::Integer, d::Integer, mapf::MAPF)
    (; g, edge_indices, edge_weights_vec) = mapf
    e = edge_indices[s, d]
    edge_weight = edge_weights_vec[e]
    indeg_s = indegree(g, s)
    outdeg_s = outdegree(g, s)
    indeg_d = indegree(g, d)
    outdeg_d = outdegree(g, d)
    return Float64[edge_weight, indeg_s, outdeg_s, indeg_d, outdeg_d]
end

function mission_features_edge(s::Integer, d::Integer, mapf::MAPF)
    (; sources, destinations) = mapf
    s_is_source = s in sources
    d_is_source = d in sources
    s_is_destination = s in destinations
    d_is_destination = d in destinations
    s_source_count = count(isequal(s), sources)
    d_source_count = count(isequal(d), sources)
    s_destination_count = count(isequal(s), destinations)
    d_destination_count = count(isequal(d), destinations)
    return Float64[
        s_is_source,
        d_is_source,
        s_is_destination,
        d_is_destination,
        s_source_count,
        d_source_count,
        s_destination_count,
        d_destination_count,
    ]
end

function conflict_features_edge(s::Integer, d::Integer, mapf::MAPF)
    (; edge_indices, vertex_conflicts, edge_conflicts) = mapf
    e = edge_indices[s, d]
    vertex_conflicts_flattened = Iterators.flatten(vertex_conflicts)
    edge_conflicts_flattened = Iterators.flatten(edge_conflicts)
    s_is_conflict = s in vertex_conflicts_flattened
    d_is_conflict = d in vertex_conflicts_flattened
    e_is_conflict = e in edge_conflicts_flattened
    s_conflict_count = count(isequal(s), vertex_conflicts_flattened)
    d_conflict_count = count(isequal(d), vertex_conflicts_flattened)
    e_conflict_count = count(isequal(e), edge_conflicts_flattened)
    return Float64[
        s_is_conflict,
        d_is_conflict,
        e_is_conflict,
        s_conflict_count,
        d_conflict_count,
        e_conflict_count,
    ]
end

function solution_features_edge(s::Integer, d::Integer, solution::Solution, mapf::MAPF)
    nb_visits_s = 0
    nb_visits_d = 0
    nb_visits_e = 0
    nb_visits_e_rev = 0
    nb_paths_visiting_s = 0
    nb_paths_visiting_d = 0
    nb_paths_visiting_e = 0
    nb_paths_visiting_e_rev = 0
    for timed_path in solution
        (; t0, path) = timed_path
        K = length(path)
        nb_visits_s += count(isequal(s), path)
        nb_visits_d += count(isequal(d), path)
        nb_paths_visiting_s += any(isequal(s), path)
        nb_paths_visiting_d += any(isequal(d), path)
        for k in 1:(K - 1)
            v1, v2 = path[k], path[k + 1]
            nb_visits_e += (v1 == s && v2 == d)
            nb_visits_e_rev += (v1 == d && v2 == s)
        end
        for k in 1:(K - 1)
            v1, v2 = path[k], path[k + 1]
            if (v1 == s && v2 == d)
                nb_paths_visiting_e += 1
                break
            end
        end
        for k in 1:(K - 1)
            v1, v2 = path[k], path[k + 1]
            if (v1 == d && v2 == s)
                nb_paths_visiting_e_rev += 1
                break
            end
        end
    end
    return Float64[
        nb_visits_s,
        nb_visits_d,
        nb_visits_e,
        nb_visits_e_rev,
        nb_paths_visiting_s,
        nb_paths_visiting_d,
        nb_paths_visiting_e,
        nb_paths_visiting_e_rev,
    ]
end

function agent_features_edge(
    s::Integer, d::Integer, a::Integer, solution::Solution, mapf::MAPF
)
    timed_path = solution[a]
    (; t0, path) = timed_path
    K = length(path)
    s_belongs_to_path = s in path
    d_belongs_to_path = d in path
    edge_belongs_to_path = false
    for k in 1:(K - 1)
        v1, v2 = path[k], path[k + 1]
        if s == v1 && d == v2
            edge_belongs_to_path = true
            break
        end
    end
    return Float64[s_belongs_to_path, d_belongs_to_path, edge_belongs_to_path]
end

function edge_embedding(s::Integer, d::Integer, a::Integer, solution::Solution, mapf::MAPF)
    f1 = graph_features_edge(s, d, mapf)
    f2 = mission_features_edge(s, d, mapf)
    f3 = conflict_features_edge(s, d, mapf)
    f4 = solution_features_edge(s, d, solution, mapf)
    f5 = agent_features_edge(s, d, a, solution, mapf)
    return vcat(f1, f2, f3, f4, f5)
end

function all_edges_embedding(a::Integer, solution::Solution, mapf::MAPF)
    (; g, edge_indices) = mapf
    ed = first(edges(g))
    E = ne(g)
    F = length(edge_embedding(src(ed), dst(ed), a, solution, mapf))
    x = Matrix{Float64}(undef, F, E)
    @threads for s in 1:nv(g)
        for d in outneighbors(g, s)
            e = edge_indices[s, d]
            x[:, e] .= edge_embedding(s, d, a, solution, mapf)
        end
    end
    return x
end
