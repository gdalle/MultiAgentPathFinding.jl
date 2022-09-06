function cooperative_astar_from_trees!(
    solution::Solution,
    mapf::MAPF{G},
    agents,
    edge_weights_vec::AbstractVector{W},
    spt_by_arr;
    window,
    show_progress=false,
) where {G,W}
    w = build_weights_matrix(mapf, edge_weights_vec)
    res = compute_reservation(solution, mapf)
    prog = Progress(length(agents); desc="Cooperative A*: ", enabled=show_progress)
    for a in agents
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        spt = spt_by_arr[arr]
        tmax = max(max_time(res), tdep) + path_length_tree(spt, dep, arr)
        heuristic(v) = spt.dists[v]
        # timed_path = TimedPath(tdep)
        # nb_windows = 1 + (tmax - tdep) ÷ window
        # for _ in 1:nb_windows
        #     emp = isempty(timed_path)
        #     if !emp && arrival_vertex(timed_path) == arr
        #         break
        #     end
        #     local_dep = emp ? dep : arrival_vertex(timed_path)
        #     local_tdep = emp ? tdep : arrival_time(timed_path)
        #     local_tmax = emp ? tdep + window : arrival_time(timed_path) + window
        #     continuation_timed_path = temporal_astar(
        #         mapf.g,
        #         w;
        #         dep=local_dep,
        #         arr=arr,
        #         tdep=local_tdep,
        #         tmax=local_tmax,
        #         res=res,
        #         heuristic=heuristic,
        #     )
        #     timed_path = concat_paths(timed_path, continuation_timed_path)
        # end
        timed_path = temporal_astar(
            mapf.g, w; dep=dep, arr=arr, tdep=tdep, tmax=tmax, res=res, heuristic=heuristic
        )
        solution[a] = timed_path
        update_reservation!(res, timed_path, mapf, a)
        next!(prog)
    end
    return nothing
end

function cooperative_astar_soft_from_trees!(
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
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        spt = spt_by_arr[arr]
        tmax = max(max_time(res), tdep) + path_length_tree(spt, dep, arr)
        heuristic(v) = spt.dists[v]
        # timed_path = TimedPath(tdep)
        # nb_windows = 1 + (tmax - tdep) ÷ window
        # for _ in 1:nb_windows
        #     emp = isempty(timed_path)
        #     if !emp && arrival_vertex(timed_path) == arr
        #         break
        #     end
        #     local_dep = emp ? dep : arrival_vertex(timed_path)
        #     local_tdep = emp ? tdep : arrival_time(timed_path)
        #     local_tmax = emp ? tdep + window : arrival_time(timed_path) + window
        #     continuation_timed_path = temporal_astar_soft(
        #         mapf.g,
        #         w;
        #         dep=local_dep,
        #         arr=arr,
        #         tdep=local_tdep,
        #         tmax=local_tmax,
        #         res=res,
        #         heuristic=heuristic,
        #         conflict_price=conflict_price,
        #     )
        #     timed_path = concat_paths(timed_path, continuation_timed_path)
        # end
        timed_path = temporal_astar_soft(
            mapf.g,
            w;
            dep=dep,
            arr=arr,
            tdep=tdep,
            tmax=tmax,
            res=res,
            heuristic=heuristic,
            conflict_price=conflict_price,
        )
        solution[a] = timed_path
        update_reservation!(res, timed_path, mapf, a)
        next!(prog)
    end
    return nothing
end

function repeated_cooperative_astar_from_trees(
    mapf::MAPF, edge_weights_vec, spt_by_arr; coop_timeout, window, show_progress=false
)
    prog = ProgressUnknown("Cooperative A* runs"; enabled=show_progress)
    total_time = 0.0
    while true
        τ1 = CPUtime_us()
        solution = empty_solution(mapf)
        agents = randperm(nb_agents(mapf))
        cooperative_astar_from_trees!(
            solution,
            mapf,
            agents,
            edge_weights_vec,
            spt_by_arr;
            window=window,
            show_progress=false,
        )
        if is_feasible(solution, mapf)
            return solution
        end
        τ2 = CPUtime_us()
        total_time += (τ2 - τ1) / 1e6
        if total_time > coop_timeout
            break
        else
            next!(prog)
        end
    end
    return empty_solution(mapf)
end

function repeated_cooperative_astar(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec;
    coop_timeout=2,
    window=10,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    return repeated_cooperative_astar_from_trees(
        mapf,
        edge_weights_vec,
        spt_by_arr;
        coop_timeout=coop_timeout,
        window=window,
        show_progress=show_progress,
    )
end
