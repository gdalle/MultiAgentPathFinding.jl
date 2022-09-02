function optimality_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec,
    spt_by_dest;
    neighborhood_size,
    max_steps_without_improvement,
    show_progress,
)
    if !is_feasible(solution, mapf)
        @warn "Infeasible starting solution"
        return solution
    end
    cost = flowtime(solution, mapf)
    steps_without_improvement = 0
    prog = ProgressUnknown("Optimality search steps: "; enabled=show_progress)
    while steps_without_improvement < max_steps_without_improvement
        next!(prog; showvalues=[(:steps_without_improvement, steps_without_improvement)])
        agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, agents, mapf)
        cooperative_astar_from_trees!(
            solution, mapf, agents, edge_weights_vec, spt_by_dest;
        )
        new_cost = flowtime(solution, mapf)
        if all_non_empty(solution) && new_cost < cost  # keep
            cost = new_cost
            steps_without_improvement = 0
        else  # revert
            for a in agents
                solution[a] = backup[a]
            end
            steps_without_improvement += 1
        end
    end
    return solution
end

function optimality_search(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec;
    neighborhood_size=10,
    max_steps_without_improvement=100,
    show_progress=false,
)
    agents = randperm(nb_agents(mapf))
    spt_by_dest = dijkstra_by_destination(
        mapf, edge_weights_vec; show_progress=show_progress
    )
    solution = cooperative_astar_from_trees(
        mapf, agents, edge_weights_vec, spt_by_dest; show_progress=show_progress
    )
    optimality_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_dest;
        neighborhood_size=neighborhood_size,
        max_steps_without_improvement=max_steps_without_improvement,
        show_progress=show_progress,
    )
    return solution
end
