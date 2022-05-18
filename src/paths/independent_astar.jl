function independent_dijkstra(mapf::MAPF, edge_weights::AbstractMatrix)
    @assert all(>=(0), edge_weights)
    A = nb_agents(mapf)
    solution = Vector{Path}(undef, A)
    for a in 1:A
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dijkstra_state = my_dijkstra(
            mapf.rev_graph,
            d;
            edge_indices=mapf.rev_edge_indices,
            edge_weights=view(edge_weights, :, a),
        )
        parents = dijkstra_state.parents
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

function independent_astar(mapf::MAPF, edge_weights::AbstractVector=mapf.edge_weights)
    A = nb_agents(mapf)
    solution = Vector{Path}(undef, A)
    for a in 1:A
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        solution[a] = temporal_astar(
            mapf.graph,
            s,
            d,
            t0;
            edge_indices=mapf.edge_indices,
            edge_weights=edge_weights,
            heuristic=heuristic,
        )
    end
    return solution
end

function independent_astar(
    mapf::MAPF, constraints, edge_weights::AbstractVector=mapf.edge_weights
)
    A = nb_agents(mapf)
    solution = Vector{Path}(undef, A)
    for a in 1:A
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        solution[a] = temporal_astar(
            mapf.graph,
            s,
            d,
            t0;
            edge_indices=mapf.edge_indices,
            edge_weights=edge_weights,
            reservation=constraints[a],
            heuristic=heuristic,
        )
    end
    return solution
end
