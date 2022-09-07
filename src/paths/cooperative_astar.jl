"""
    cooperative_astar_from_trees!(
        solution, mapf, agents, edge_weights_vec, spt_by_arr; window
    )

Modify a `Solution` by applying [`temporal_astar`](@ref) to a subset of agents while avoiding conflicts thanks to a `Reservation`.

# Arguments

- `agents`: subset of agents taken in order
- `spt_by_arr`: dictionary of [`ShortestPathTree`](@ref)s, one for each arrival vertex
- `window`: size of the chunks into which the time horizon is divided (temporal A* is run once for each chunk, iteratively lengthening an agent's path)
"""
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
        timed_path = TimedPath(tdep)
        nb_windows = 1 + (tmax - tdep) ÷ window
        for _ in 1:nb_windows
            emp = isempty(timed_path)
            if !emp && arrival_vertex(timed_path) == arr
                break
            end
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
            )
            timed_path = concat_paths(timed_path, continuation_timed_path)
        end
        solution[a] = timed_path
        update_reservation!(res, timed_path, mapf, a)
        next!(prog)
    end
    return nothing
end

"""
    cooperative_astar_from_trees_soft!(
        solution, mapf, agents, edge_weights_vec, spt_by_arr; window
    )

Does the same things as [`cooperative_astar_from_trees!`](@ref) but with [`temporal_astar_soft`](@ref) as a basic subroutine.

# Arguments

- `agents`, `spt_by_arr`, `window`: see [`cooperative_astar_from_trees!`](@ref)
- `conflict_price`: see [`temporal_astar_soft`](@ref)
"""
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
        timed_path = TimedPath(tdep)
        nb_windows = 1 + (tmax - tdep) ÷ window
        for _ in 1:nb_windows
            emp = isempty(timed_path)
            if !emp && arrival_vertex(timed_path) == arr
                break
            end
            local_dep = emp ? dep : arrival_vertex(timed_path)
            local_tdep = emp ? tdep : arrival_time(timed_path)
            local_tmax = emp ? tdep + window : arrival_time(timed_path) + window
            continuation_timed_path = temporal_astar_soft(
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
        next!(prog)
    end
    return nothing
end

"""
    repeated_cooperative_astar_from_trees(
        mapf, edge_weights_vec, spt_by_arr; coop_timeout, window
    )

Apply [`cooperative_astar_from_trees!`](@ref) repeatedly until a feasible solution is found or the timeout given by `coop_timeout` is reached.
"""
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

"""
    repeated_cooperative_astar(mapf, edge_weights_vec; coop_timeout, window)

Compute a dictionary of [`ShortestPathTree`](@ref)s with [`dijkstra_by_arrival`](@ref), and then apply [`repeated_cooperative_astar_from_trees`](@ref).
"""
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
