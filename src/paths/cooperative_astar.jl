function cooperative_astar!(
    solution::Solution,
    agents::AbstractVector{Int},
    mapf::MAPF,
    edge_weights_vec::AbstractVector=mapf.edge_weights_vec;
    conflict_price=Inf,
    show_progress=false,
)
    (;
        graph,
        edge_indices,
        sources,
        destinations,
        starting_times,
        distances_to_destinations,
    ) = mapf
    reservation = compute_reservation(solution, mapf)
    prog = Progress(length(agents); enabled=show_progress)
    for a in agents
        next!(prog)
        s, d, t0 = sources[a], destinations[a], starting_times[a]
        dist = distances_to_destinations[d]
        heuristic(v) = dist[v]
        timed_path = temporal_astar(
            graph,
            s,
            d,
            t0,
            edge_indices,
            edge_weights_vec;
            heuristic=heuristic,
            reservation=reservation,
            conflict_price=conflict_price,
        )
        solution[a] = timed_path
        update_reservation!(reservation, timed_path, mapf)
    end
end

function cooperative_astar(
    mapf::MAPF,
    agents::AbstractVector{Int}=randperm(nb_agents(mapf)),
    edge_weights_vec::AbstractVector=mapf.edge_weights_vec;
    conflict_price=Inf,
    show_progress=false,
)
    solution = [TimedPath(mapf.sources[a], Int[]) for a in 1:nb_agents(mapf)]
    cooperative_astar!(
        solution,
        agents,
        mapf,
        edge_weights_vec;
        conflict_price=conflict_price,
        show_progress=show_progress,
    )
    return solution
end
