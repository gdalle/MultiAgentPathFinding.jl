function cooperative_astar_from_trees!(
    solution::Solution,
    mapf::MAPF,
    agents,
    edge_weights_vec::AbstractVector{W},
    spt_by_dest;
    conflict_price=Inf,
    show_progress=false,
) where {W}
    w = build_weights_matrix(mapf, edge_weights_vec)
    res = compute_reservation(solution, mapf)
    prog = Progress(length(agents); desc="Cooperative A*: ", enabled=show_progress)
    for a in agents
        next!(prog)
        s, d = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        spt = spt_by_dest[d]
        dists = spt.dists
        if isnothing(dists[s]) || is_arrival_reached(res, d)
            timed_path = TimedPath(tdep, Int[])
        else
            tmax = max(tdep, max_time(res)) + path_length(spt, s, d)
            heuristic(v) = dists[v]
            timed_path = temporal_astar(
                mapf.g,
                s,
                d,
                tdep,
                tmax,
                w,
                res;
                heuristic=heuristic,
                conflict_price=conflict_price,
            )
        end
        solution[a] = timed_path
        update_reservation!(res, timed_path, mapf)
    end
    return nothing
end

function cooperative_astar_from_trees(
    mapf::MAPF,
    agents,
    edge_weights_vec,
    spt_by_dest;
    conflict_price=Inf,
    show_progress=false,
)
    solution = empty_solution(mapf)
    cooperative_astar_from_trees!(
        solution,
        mapf,
        agents,
        edge_weights_vec,
        spt_by_dest;
        conflict_price=conflict_price,
        show_progress=show_progress,
    )
    if !is_feasible(solution, mapf)
        @warn "Infeasible solution"
    end
    return solution
end

function cooperative_astar(
    mapf::MAPF,
    agents=randperm(nb_agents(mapf)),
    edge_weights_vec=mapf.edge_weights_vec;
    conflict_price=Inf,
    show_progress=false,
)
    spt_by_dest = dijkstra_by_destination(
        mapf, edge_weights_vec; show_progress=show_progress
    )
    return cooperative_astar_from_trees(
        mapf,
        agents,
        edge_weights_vec,
        spt_by_dest;
        conflict_price=conflict_price,
        show_progress=show_progress,
    )
end
