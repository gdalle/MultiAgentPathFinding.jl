function cooperative_astar_from_trees!(
    solution::Solution,
    mapf::MAPF,
    agents,
    edge_weights_vec::AbstractVector{W},
    spt_by_arr;
    window,
    conflict_price,
    show_progress=false,
) where {W}
    w = build_weights_matrix(mapf, edge_weights_vec)
    res = compute_reservation(solution, mapf)
    prog = Progress(length(agents); desc="Cooperative A*: ", enabled=show_progress)
    for a in agents
        next!(prog)
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        spt = spt_by_arr[arr]
        heuristic(v) = spt.dists[v]
        tdep = mapf.departure_times[a]
        tmax = max(max_time(res), tdep) + path_length_tree(spt, dep, arr)
        nb_windows = 1 + (tmax - tdep) ÷ window
        timed_path = TimedPath(tdep)
        for _ in 1:nb_windows
            arrival_vertex(timed_path) == arr && break
            emp = isempty(timed_path)
            local_dep = emp ? dep : arrival_vertex(timed_path)
            local_tdep = emp ? tdep : arrival_time(timed_path)
            local_tmax = emp ? tdep + window : arrival_time(timed_path) + window
            continuation_timed_path = temporal_astar(
                mapf.g,
                w;
                dep=local_dep,
                arr=arr,
                tdep=local_tdep,
                tmax=local_tmax,
                res=res,
                heuristic=heuristic,
                conflict_price=conflict_price,
            )
            timed_path = concat_paths(timed_path, continuation_timed_path)
        end
        solution[a] = timed_path
        update_reservation!(res, timed_path, mapf, a)
    end
    return nothing
end

function cooperative_astar_from_trees(
    mapf::MAPF,
    agents,
    edge_weights_vec,
    spt_by_arr;
    window,
    conflict_price,
    show_progress=false,
)
    solution = empty_solution(mapf)
    cooperative_astar_from_trees!(
        solution,
        mapf,
        agents,
        edge_weights_vec,
        spt_by_arr;
        window=window,
        conflict_price=conflict_price,
        show_progress=show_progress,
    )
    return solution
end

function cooperative_astar(
    mapf::MAPF,
    agents=randperm(nb_agents(mapf)),
    edge_weights_vec=mapf.edge_weights_vec;
    window=10,
    conflict_price=Inf,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    return cooperative_astar_from_trees(
        mapf,
        agents,
        edge_weights_vec,
        spt_by_arr;
        window=window,
        conflict_price=conflict_price,
        show_progress=show_progress,
    )
end
