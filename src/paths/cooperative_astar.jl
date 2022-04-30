function cooperative_astar!(
    solution::Solution,
    agents::AbstractVector{Int},
    mapf::MAPF,
    edge_weights::AbstractVector=mapf.edge_weights,
)
    forbidden_vertices = compute_reservation(solution, mapf)
    @showprogress for a in agents
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        path = temporal_astar(
            mapf.graph,
            s,
            d,
            t0;
            edge_indices=mapf.edge_indices,
            edge_weights=edge_weights,
            heuristic=heuristic,
            forbidden_vertices=forbidden_vertices,
        )
        solution[a] = path
        update_reservation(forbidden_vertices, path, mapf)
    end
end

function cooperative_astar(
    mapf::MAPF,
    permutation::AbstractVector{Int}=1:nb_agents(mapf),
    edge_weights::AbstractVector=mapf.edge_weights,
)
    solution = [Path() for a in 1:nb_agents(mapf)]
    cooperative_astar!(solution, permutation, mapf, edge_weights)
    return solution
end
