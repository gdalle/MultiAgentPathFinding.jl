function optimality_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec,
    spt_by_arr;
    window,
    neighborhood_size,
    max_stagnation,
    show_progress,
)
    is_feasible(solution, mapf) || return solution
    cost = flowtime(solution, mapf)
    stagnation = 0
    prog = ProgressUnknown("Optimality search steps: "; enabled=show_progress)
    while stagnation < max_stagnation
        next!(prog; showvalues=[(:stagnation, stagnation)])
        agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, agents, mapf)
        single_cooperative_astar_from_trees!(
            solution,
            mapf,
            agents,
            edge_weights_vec,
            spt_by_arr;
            window=window,
            conflict_price=Inf,
        )
        new_cost = flowtime(solution, mapf)
        if is_feasible(solution, mapf) && new_cost < cost  # keep
            cost = new_cost
            stagnation = 0
        else  # revert
            for a in agents
                solution[a] = backup[a]
            end
            stagnation += 1
        end
    end
    return solution
end

function optimality_search(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec;
    coop_max_trials=10,
    window=10,
    neighborhood_size=10,
    max_stagnation=100,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    solution = cooperative_astar_from_trees(
        mapf,
        edge_weights_vec,
        spt_by_arr;
        max_trials=coop_max_trials,
        window=window,
        conflict_price=Inf,
        show_progress=show_progress,
    )
    optimality_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        window=window,
        neighborhood_size=neighborhood_size,
        max_stagnation=max_stagnation,
        show_progress=show_progress,
    )
    return solution
end
