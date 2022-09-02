function cooperative_astar!(
    solution::Solution,
    mapf::MAPF,
    agents,
    edge_weights_vec,
    spt_by_dest;
    conflict_price=Inf,
    show_progress=false,
)
    w = build_weights_matrix(mapf, edge_weights_vec)
    res = compute_reservation(solution, mapf)
    prog = Progress(length(agents); enabled=show_progress)
    for i in eachindex(agents)
        next!(prog)
        a = agents[i]
        s, d = mapf.departures[a], mapf.arrivals[a]
        tdep, tarr = mapf.departure_times[a], mapf.arrival_times[a]
        dists = spt_by_dest[d].dists
        heuristic(v) = dists[v]
        timed_path = temporal_astar(
            mapf.g,
            s,
            d,
            tdep,
            tarr,
            w,
            res;
            heuristic=heuristic,
            conflict_price=conflict_price,
        )
        solution[a] = timed_path
        update_reservation!(res, timed_path, mapf)
    end
    return nothing
end

function cooperative_astar(
    mapf::MAPF,
    agents=randperm(nb_agents(mapf)),
    edge_weights_vec=mapf.edge_weights_vec,
    spt_by_dest=dijkstra_by_destination(mapf, edge_weights_vec; show_progress=false);
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
