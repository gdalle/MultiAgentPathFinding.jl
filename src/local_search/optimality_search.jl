function optimality_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec,
    spt_by_arr;
    optimality_timeout,
    window,
    neighborhood_size,
    show_progress,
)
    is_feasible(solution, mapf) || return solution
    cost = flowtime(solution, mapf)
    prog = ProgressUnknown("Optimality search steps: "; enabled=show_progress)
    total_time = 0.0
    while true
        τ1 = CPUtime_us()
        neighborhood_agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, neighborhood_agents, mapf)
        cooperative_astar_from_trees!(
            solution, mapf, neighborhood_agents, edge_weights_vec, spt_by_arr; window=window
        )
        new_cost = flowtime(solution, mapf)
        if is_feasible(solution, mapf) && new_cost < cost
            cost = new_cost
        else
            for a in neighborhood_agents
                solution[a] = backup[a]
            end
        end
        τ2 = CPUtime_us()
        total_time += (τ2 - τ1) / 1e6
        if total_time > optimality_timeout
            break
        else
            next!(prog; showvalues=[(:cost, cost)])
        end
    end
    return solution
end

function optimality_search(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec;
    coop_timeout=2,
    optimality_timeout=2,
    window=10,
    neighborhood_size=10,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    solution = repeated_cooperative_astar_from_trees(
        mapf,
        edge_weights_vec,
        spt_by_arr;
        coop_timeout=coop_timeout,
        window=window,
        show_progress=show_progress,
    )
    optimality_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        optimality_timeout=optimality_timeout,
        window=window,
        neighborhood_size=neighborhood_size,
        show_progress=show_progress,
    )
    return solution
end
