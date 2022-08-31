## Dijkstra

function dijkstra_by_agent(
    mapf::MAPF, edge_weights_mat::AbstractMatrix{<:Real}; show_progress
)
    (; g, sources) = mapf
    A = nb_agents(mapf)
    spt_by_agent = Vector{ShortestPathTree}(undef, A)
    prog = Progress(A; desc="Dijkstra by agent: ", enabled=show_progress)
    for a in 1:A
        next!(prog)
        wa = build_weights_matrix(mapf, edge_weights_mat[:, a])
        spt_by_agent[a] = forward_dijkstra(g, sources[a], wa)
    end
    return spt_by_agent
end

function independent_dijkstra(
    mapf::MAPF, edge_weights_mat::AbstractMatrix{<:Real}; show_progress
)
    (; sources, destinations, departure_times) = mapf
    spt_by_agent = dijkstra_by_agent(mapf, edge_weights_mat; show_progress=show_progress)
    A = nb_agents(mapf)
    solution = Vector{TimedPath}(undef, A)
    for a in 1:A
        s, d, t0 = sources[a], destinations[a], departure_times[a]
        solution[a] = build_timed_path(spt_by_agent[a], t0, s, d)
    end
    return solution
end

## Coop A*

function cooperative_astar!(
    solution::Solution,
    mapf::MAPF,
    agents::AbstractVector{<:Integer},
    edge_weights_mat::AbstractMatrix{<:Real};
    conflict_price,
    show_progress,
)
    (; g, sources, destinations, departure_times) = mapf
    reservation = compute_reservation(solution, mapf)
    prog = Progress(length(agents); enabled=show_progress)
    for a in agents
        next!(prog)
        s, d, t0 = sources[a], destinations[a], departure_times[a]
        wa = build_weights_matrix(mapf, edge_weights_mat[:, a])
        dists = backward_dijkstra(g, d, wa).dists
        heuristic(v) = dists[v]
        timed_path = temporal_astar(
            g, s, d, t0, wa, reservation; heuristic=heuristic, conflict_price=conflict_price
        )
        solution[a] = timed_path
        update_reservation!(reservation, timed_path, mapf)
    end
    return nothing
end

function cooperative_astar(
    mapf::MAPF,
    agents::AbstractVector{<:Integer},
    edge_weights_mat::AbstractMatrix{<:Real};
    conflict_price=Inf,
    show_progress=false,
)
    solution = empty_solution(mapf)
    cooperative_astar!(
        solution,
        mapf,
        agents,
        edge_weights_mat;
        conflict_price=conflict_price,
        show_progress=show_progress,
    )
    return solution
end
