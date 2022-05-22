function cooperative_astar!(
    solution::Solution,
    agents::AbstractVector{Int},
    mapf::MAPF;
    conflict_price=Inf,
    show_progress=false,
)
    (;
        graph,
        edge_indices,
        edge_weights_vec,
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
        dists = distances_to_destinations[d]
        heuristic(v) = dists[v]
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

function cooperative_astar!(
    solution::Solution,
    agents::AbstractVector{Int},
    mapf::MAPF,
    edge_weights_mat::AbstractMatrix;
    conflict_price=Inf,
    show_progress=false,
)
    (;
        graph,
        edge_indices,
        sources,
        destinations,
        starting_times,
    ) = mapf

    reservation = compute_reservation(solution, mapf)
    prog = Progress(length(agents); enabled=show_progress)
    for a in agents
        next!(prog)
        s, d, t0 = sources[a], destinations[a], starting_times[a]
        edge_weights_vec_for_a = view(edge_weights_mat, :, a)
        dists = backward_dijkstra(graph, d, edge_indices, edge_weights_vec_for_a).dists
        heuristic(v) = dists[v]
        timed_path = temporal_astar(
            graph,
            s,
            d,
            t0,
            edge_indices,
            edge_weights_vec_for_a;
            heuristic=heuristic,
            reservation=reservation,
            conflict_price=conflict_price,
        )
        solution[a] = timed_path
        update_reservation!(reservation, timed_path, mapf)
    end
end

function cooperative_astar(
    mapf::MAPF, agents::AbstractVector{Int}; conflict_price=Inf, show_progress=false
)
    solution = [TimedPath(mapf.starting_times[a], Int[]) for a in 1:nb_agents(mapf)]
    cooperative_astar!(
        solution, agents, mapf; conflict_price=conflict_price, show_progress=show_progress
    )
    return solution
end

function cooperative_astar(
    mapf::MAPF,
    agents::AbstractVector{Int},
    edge_weights_mat::AbstractMatrix;
    conflict_price=Inf,
    show_progress=false,
)
    solution = [TimedPath(mapf.starting_times[a], Int[]) for a in 1:nb_agents(mapf)]
    cooperative_astar!(
        solution,
        agents,
        mapf,
        edge_weights_mat;
        conflict_price=conflict_price,
        show_progress=show_progress,
    )
    return solution
end
