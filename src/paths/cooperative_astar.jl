function cooperative_astar!(
    solution::Solution,
    agents::AbstractVector{Int},
    mapf::MAPF,
    edge_weights_vec::AbstractVector,
    shortest_path_trees::Dict;
    conflict_price=Inf,
    show_progress=false,
)
    prog = Progress(length(agents); enabled=show_progress)
    (; g, sources, destinations, starting_times) = mapf
    w = build_weights_matrix(mapf, edge_weights_vec)
    reservation = compute_reservation(solution, mapf)
    for a in agents
        next!(prog)
        s, d, t0 = sources[a], destinations[a], starting_times[a]
        dists = shortest_path_trees[d].dists
        heuristic(v) = dists[v]
        timed_path = temporal_astar(
            g, s, d, t0, w, reservation; heuristic=heuristic, conflict_price=conflict_price
        )
        solution[a] = timed_path
        update_reservation!(reservation, timed_path, mapf)
    end
    return nothing
end

function cooperative_astar!(
    solution::Solution,
    agents::AbstractVector{Int},
    mapf::MAPF,
    edge_weights_mat::AbstractMatrix;
    conflict_price=Inf,
    show_progress=false,
)
    prog = Progress(length(agents); enabled=show_progress)
    (; g, sources, destinations, starting_times) = mapf
    reservation = compute_reservation(solution, mapf)
    for a in agents
        next!(prog)
        s, d, t0 = sources[a], destinations[a], starting_times[a]
        edge_weights_vec_for_a = view(edge_weights_mat, :, a)
        w_for_a = build_weights_matrix(mapf, edge_weights_vec_for_a)
        dists = backward_dijkstra(g, d, w_for_a).dists
        heuristic(v) = dists[v]
        timed_path = temporal_astar(
            g,
            s,
            d,
            t0,
            w_for_a,
            reservation;
            heuristic=heuristic,
            conflict_price=conflict_price,
        )
        solution[a] = timed_path
        update_reservation!(reservation, timed_path, mapf)
    end
    return nothing
end

function cooperative_astar(
    mapf::MAPF,
    agents::AbstractVector{Int},
    edge_weights_vec::AbstractVector=mapf.edge_weights_vec;
    conflict_price=Inf,
    show_progress=false,
)
    solution = [TimedPath(mapf.starting_times[a], Int[]) for a in 1:nb_agents(mapf)]
    shortest_path_trees = dijkstra_to_destinations(mapf, edge_weights_vec)
    cooperative_astar!(
        solution,
        agents,
        mapf,
        edge_weights_vec,
        shortest_path_trees;
        conflict_price=conflict_price,
        show_progress=show_progress,
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
