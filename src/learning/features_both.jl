function joint_features_edge_agent(
    s::Integer, d::Integer, a::Integer, solution::Solution, mapf::MAPF
)
    belongs_to_path = false
    path = solution[a]
    n = length(path)
    for ((t1, v1), (t2, v2)) in zip(view(path, 1:(n - 1)), view(path, 2:n))
        if (v1, v2) == (s, d)
            belongs_to_path = true
        end
    end
    return Float64[belongs_to_path]
end

function all_features_edge_agent(
    s::Integer, d::Integer, a::Integer, solution::Solution, mapf::MAPF
)
    return vcat(
        constant_features_edge(s, d, mapf),
        solution_features_edge(s, d, solution, mapf),
        joint_features_edge_agent(s, d, a, solution, mapf),
    )
end

function edges_agents_embedding(mapf::MAPF)
    solution = independent_dijkstra(mapf)
    test_ed = first(edges(mapf.graph))
    nb_features = length(
        all_features_edge_agent(src(test_ed), dst(test_ed), 1, solution, mapf)
    )
    x = Array{Float64,3}(undef, nb_features, ne(mapf.graph), nb_agents(mapf))
    for (e, ed) in enumerate(edges(mapf.graph))
        for a in 1:nb_agents(mapf)
            x[:, e, a] = all_features_edge_agent(src(ed), dst(ed), a, solution, mapf)
        end
    end
    return x
end
