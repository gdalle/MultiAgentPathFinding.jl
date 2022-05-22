function independent_dijkstra(
    mapf::MAPF, edge_weights_vec::AbstractVector=mapf.edge_weights_vec
)
    (; graph, edge_indices, sources, destinations, starting_times) = mapf
    @assert all(>=(0), edge_weights_vec)
    A = nb_agents(mapf)
    solution = Vector{TimedPath}(undef, A)
    shortest_path_trees = Dict(
        d => backward_dijkstra(graph, d, edge_indices, edge_weights_vec) for
        d in unique(destinations)
    )
    for a in 1:A
        s, d, t0 = sources[a], destinations[a], starting_times[a]
        solution[a] = build_dijkstra_path(shortest_path_trees[d], t0, s, d)
    end
    return solution
end

function agent_dijkstra(
    a::Integer, mapf::MAPF, edge_weights_vec::AbstractVector=mapf.edge_weights_vec
)
    (; graph, edge_indices, sources, destinations, starting_times) = mapf
    @assert all(>=(0), edge_weights_vec)
    s, d, t0 = sources[a], destinations[a], starting_times[a]
    shortest_path_tree = forward_dijkstra(graph, s, edge_indices, edge_weights_vec)
    path = build_dijkstra_path(shortest_path_tree, t0, s, d)
    return path
end
