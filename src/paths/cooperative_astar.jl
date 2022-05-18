function cooperative_astar!(
    solution::Solution,
    agents::AbstractVector{Int},
    mapf::MAPF,
    edge_weights::AbstractVector=mapf.edge_weights;
    conflict_price=Inf,
    show_progress=false,
)
    A = nb_agents(mapf)
    reservation = compute_reservation(solution, mapf)
    prog = Progress(A; enabled=show_progress)
    for a in agents
        next!(prog)
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
            reservation=reservation,
            conflict_price=conflict_price,
        )
        solution[a] = path
        update_reservation!(reservation, path, mapf)
    end
end

function cooperative_astar(
    mapf::MAPF,
    permutation::AbstractVector{Int}=1:nb_agents(mapf),
    edge_weights::AbstractVector=mapf.edge_weights;
    conflict_price=Inf,
    show_progress=false,
)
    solution = [Path() for a in 1:nb_agents(mapf)]
    cooperative_astar!(
        solution,
        permutation,
        mapf,
        edge_weights;
        conflict_price=conflict_price,
        show_progress=show_progress,
    )
    return solution
end
