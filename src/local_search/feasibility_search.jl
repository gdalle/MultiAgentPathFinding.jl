function feasibility_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec,
    spt_by_arr;
    window,
    neighborhood_size,
    conflict_price,
    conflict_price_increase,
    max_steps_without_improvement,
    show_progress,
)
    is_individually_feasible(solution, mapf) || return solution
    conflicts_count = count_conflicts(solution, mapf)
    steps_without_improvement = 0
    prog = ProgressUnknown("Feasibility search steps: "; enabled=show_progress)
    while conflicts_count > 0 && steps_without_improvement < max_steps_without_improvement
        next!(
            prog;
            showvalues=[
                (:conflicts_count, conflicts_count),
                (:steps_without_improvement, steps_without_improvement),
            ],
        )
        neighborhood_agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, neighborhood_agents, mapf)
        single_cooperative_astar_from_trees!(
            solution,
            mapf,
            neighborhood_agents,
            edge_weights_vec,
            spt_by_arr;
            window=window,
            conflict_price=conflict_price,
        )
        new_conflicts_count = count_conflicts(solution, mapf)
        if (
            is_individually_feasible(solution, mapf) &&
            new_conflicts_count < conflicts_count
        )  # keep
            conflicts_count = new_conflicts_count
            steps_without_improvement = 0
        else  # revert
            for a in neighborhood_agents
                solution[a] = backup[a]
            end
            steps_without_improvement += 1
        end
        conflict_price *= (one(conflict_price_increase) + conflict_price_increase)
    end
    return solution
end

function feasibility_search(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec;
    window=10,
    neighborhood_size=10,
    conflict_price=1e-1,
    conflict_price_increase=1e-2,
    max_steps_without_improvement=100,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    solution = independent_dijkstra_from_trees(mapf, spt_by_arr)
    feasibility_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        window=window,
        neighborhood_size=neighborhood_size,
        conflict_price=conflict_price,
        conflict_price_increase=conflict_price_increase,
        max_steps_without_improvement=max_steps_without_improvement,
        show_progress=show_progress,
    )
    return solution
end
