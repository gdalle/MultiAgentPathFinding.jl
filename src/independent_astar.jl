function independent_astar(mapf)
    graph, edge_weights = mapf.graph, mapf.edge_weights
    A = nb_agents(mapf)
    solution = Vector{Path}(undef, A)
    for a in 1:A
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        solution[a] = temporal_astar(
            graph, s, d, t0; edge_weights=edge_weights, heuristic=heuristic
        )
    end
    return solution
end

function independent_astar(mapf, constraints)
    graph, edge_weights = mapf.graph, mapf.edge_weights
    A = nb_agents(mapf)
    solution = Vector{Path}(undef, A)
    for a in 1:A
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        forbidden_vertices = constraints[a]
        solution[a] = temporal_astar(
            graph,
            s,
            d,
            t0;
            edge_weights=edge_weights,
            forbidden_vertices=forbidden_vertices,
            heuristic=heuristic,
        )
    end
    return solution
end
