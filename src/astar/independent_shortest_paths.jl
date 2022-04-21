function independent_shortest_paths(mapf::MAPF; edge_weights=mapf.edge_weights)
    @assert minimum(findnz(edge_weights)[3]) > 0.
    A = nb_agents(mapf)
    unique_destinations = unique(mapf.destinations)
    dijkstra_states = Dict()
    for d in unique_destinations
        dijkstra_states[d] = dijkstra_shortest_paths(mapf.rev_graph, d, edge_weights')
    end
    solution = Vector{Path}(undef, A)
    for a in 1:A
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        parents = dijkstra_states[d].parents
        t, v = t0, s
        path = [(t, v)]
        while v != d
            v = parents[v]
            t += 1
            push!(path, (t, v))
        end
        solution[a] = path
    end
    return solution
end

function independent_astar(mapf::MAPF)
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

function independent_astar(mapf::MAPF, constraints)
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
