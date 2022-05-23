function dijkstra_to_destinations(
    mapf::MAPF, edge_weights_vec::AbstractVector=mapf.edge_weights_vec
)
    @assert all(>=(0), edge_weights_vec)
    (; g, destinations) = mapf
    w = build_weights_matrix(mapf, edge_weights_vec)
    unique_destinations = unique(destinations)
    UD = length(unique_destinations)
    shortest_path_trees_vec = Vector{ShortestPathTree}(undef, UD)
    @threads for k in 1:UD
        shortest_path_trees_vec[k] = backward_dijkstra(g, unique_destinations[k], w)
    end
    shortest_path_trees = Dict{Int,ShortestPathTree}(
        unique_destinations[k] => shortest_path_trees_vec[k] for k in 1:UD
    )
    return shortest_path_trees
end

function independent_dijkstra(
    mapf::MAPF,
    edge_weights_vec::AbstractVector=mapf.edge_weights_vec,
    shortest_path_trees::Dict=dijkstra_to_destinations(mapf, edge_weights_vec),
)
    (; sources, destinations, starting_times) = mapf
    A = nb_agents(mapf)
    solution = Vector{TimedPath}(undef, A)
    for a in 1:A
        s, d, t0 = sources[a], destinations[a], starting_times[a]
        solution[a] = build_dijkstra_path(shortest_path_trees[d], t0, s, d)
    end
    return solution
end

function agent_dijkstra(
    a::Integer, mapf::MAPF, edge_weights_vec::AbstractVector=mapf.edge_weights_vec
)
    @assert all(>=(0), edge_weights_vec)
    (; g, sources, destinations, starting_times) = mapf
    w = build_weights_matrix(mapf, edge_weights_vec)
    s, d, t0 = sources[a], destinations[a], starting_times[a]
    shortest_path_tree = forward_dijkstra(g, s, w)
    timed_path = build_dijkstra_path(shortest_path_tree, t0, s, d)
    return timed_path
end

function independent_dijkstra(mapf::MAPF, edge_weights_mat::AbstractMatrix)
    A = nb_agents(mapf)
    solution = Vector{TimedPath}(undef, A)
    @threads for a in 1:A
        solution[a] = agent_dijkstra(a, mapf, edge_weights_mat[:, a])
    end
    return solution
end
