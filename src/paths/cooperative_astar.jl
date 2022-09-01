function cooperative_astar!(
    solution::Solution,
    mapf::MAPF,
    agents::AbstractVector{<:Integer},
    edge_weights_vec::AbstractVector{W},
    spt_by_dest::Dict{Int,<:ShortestPathTree};
    conflict_price=Inf,
    show_progress=false,
) where {W}
    (; g, departures, arrivals, departure_times) = mapf
    w = build_weights_matrix(mapf, edge_weights_vec)
    reservation = compute_reservation(solution, mapf)
    prog = Progress(length(agents); enabled=show_progress)
    for a in agents
        next!(prog)
        s, d, t0 = departures[a], arrivals[a], departure_times[a]
        dists = spt_by_dest[d].dists
        heuristic(v) = dists[v]
        timed_path = temporal_astar(
            g, s, d, t0, w, reservation; heuristic=heuristic, conflict_price=conflict_price
        )
        solution[a] = timed_path
        update_reservation!(reservation, timed_path, mapf)
    end
    return nothing
end

function cooperative_astar(
    mapf::MAPF,
    agents::AbstractVector{<:Integer}=randperm(nb_agents(mapf)),
    edge_weights_vec::AbstractVector{<:Real}=mapf.edge_weights_vec,
    spt_by_dest::Dict{Int,<:ShortestPathTree}=dijkstra_by_destination(
        mapf, edge_weights_vec; show_progress=false
    );
    conflict_price=Inf,
    show_progress=false,
)
    solution = empty_solution(mapf)
    cooperative_astar!(
        solution,
        mapf,
        agents,
        edge_weights_vec,
        spt_by_dest;
        conflict_price=conflict_price,
        show_progress=show_progress,
    )
    return solution
end
