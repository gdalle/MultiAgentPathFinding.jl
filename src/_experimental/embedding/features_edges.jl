function graph_features_edge(s::Integer, d::Integer, mapf::MAPF)
    (; g, edge_indices, edge_weights_vec) = mapf
    e = edge_indices[s, d]
    edge_weight = edge_weights_vec[e]
    indeg_s = indegree(g, s)
    outdeg_s = outdegree(g, s)
    indeg_d = indegree(g, d)
    outdeg_d = outdegree(g, d)
    return (
        Float64(edge_weight),
        Float64(indeg_s),
        Float64(outdeg_s),
        Float64(indeg_d),
        Float64(outdeg_d),
    )
end

function mission_features_edge(s::Integer, d::Integer, mapf::MAPF)
    (; departures, arrivals) = mapf
    s_source_count = 0
    d_source_count = 0
    for v in departures
        if v == s
            s_source_count += 1
        end
        if v == d
            d_source_count += 1
        end
    end
    s_destination_count = 0
    d_destination_count = 0
    for v in arrivals
        if v == s
            s_destination_count += 1
        end
        if v == d
            d_destination_count += 1
        end
    end
    s_is_source = (s_source_count > 0)
    d_is_source = (d_source_count > 0)
    s_is_destination = (s_destination_count > 0)
    d_is_destination = (d_destination_count > 0)
    return (
        Float64(s_is_source),
        Float64(d_is_source),
        Float64(s_is_destination),
        Float64(d_is_destination),
        Float64(s_source_count),
        Float64(d_source_count),
        Float64(s_destination_count),
        Float64(d_destination_count),
    )
end

function conflict_features_edge(s::Integer, d::Integer, mapf::MAPF)
    (; edge_indices, vertex_conflicts, edge_conflicts) = mapf
    e = edge_indices[s, d]
    s_conflict_count = 0
    d_conflict_count = 0
    for v in Iterators.flatten(vertex_conflicts)
        if v == s
            s_conflict_count += 1
        end
        if v == d
            d_conflict_count += 1
        end
    end
    s_is_conflict = s_conflict_count > 0
    d_is_conflict = d_conflict_count > 0
    return (
        Float64(s_is_conflict),
        Float64(d_is_conflict),
        Float64(s_conflict_count),
        Float64(d_conflict_count),
    )
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
        local_visits_s = count(isequal(s), path)
        local_visits_d = count(isequal(d), path)
        local_visits_e = 0
        local_visits_e_rev = 0
        for k in 1:(K - 1)
            v1, v2 = path[k], path[k + 1]
            local_visits_e += (v1 == s && v2 == d)
            local_visits_e_rev += (v1 == d && v2 == s)
        end
        nb_visits_s += local_visits_s
        nb_visits_d += local_visits_d
        nb_visits_e += local_visits_e
        nb_visits_e_rev += local_visits_e_rev
        nb_paths_visiting_s += (local_visits_s > 0)
        nb_paths_visiting_d += (local_visits_d > 0)
        nb_paths_visiting_e += (local_visits_e > 0)
        nb_paths_visiting_e_rev += (local_visits_e_rev > 0)
    end
    return (
        Float64(nb_visits_s),
        Float64(nb_visits_d),
        Float64(nb_visits_e),
        Float64(nb_visits_e_rev),
        Float64(nb_paths_visiting_s),
        Float64(nb_paths_visiting_d),
        Float64(nb_paths_visiting_e),
        Float64(nb_paths_visiting_e_rev),
    )
end
