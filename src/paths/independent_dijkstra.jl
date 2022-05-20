function independent_dijkstra(mapf::MAPF, edge_weights::AbstractVector=mapf.edge_weights)
    @assert all(>=(0), edge_weights)
    A = nb_agents(mapf)
    solution = Vector{Path}(undef, A)
    shortest_path_trees = Dict(
        d => custom_dijkstra(
            mapf.rev_graph,
            d;
            edge_indices=mapf.rev_edge_indices,
            edge_weights=edge_weights,
        ) for d in unique(mapf.destinations)
    )
    for a in 1:A
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        path = build_dijkstra_path_rev(shortest_path_trees[d], t0, s, d)
        solution[a] = path
    end
    return solution
end

function independent_dijkstra(
    a::Integer, mapf::MAPF, edge_weights::AbstractVector=mapf.edge_weights
)
    @assert all(>=(0), edge_weights)
    s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
    shortest_path_tree = custom_dijkstra(
        mapf.rev_graph, d; edge_indices=mapf.rev_edge_indices, edge_weights=edge_weights
    )
    path = build_dijkstra_path_rev(shortest_path_tree, t0, s, d)
    return path
end
