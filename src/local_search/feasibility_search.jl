function feasibility_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec,
    spt_by_dest;
    neighborhood_size,
    conflict_price,
    conflict_price_increase,
    max_steps_without_improvement,
    show_progress,
)
    A = nb_agents(mapf)
    @assert all_non_empty(solution)
    conflicts_count = count_conflicts(solution, mapf)
    steps_without_improvement = 0
    prog = ProgressUnknown("Feasibility search steps: "; enabled=show_progress)
    while !is_feasible(solution, mapf)
        next!(
            prog;
            showvalues=[
                (:conflicts_count, conflicts_count),
                (:steps_without_improvement, steps_without_improvement),
            ],
        )
        neighborhood_agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, neighborhood_agents, mapf)
        cooperative_astar_from_trees!(
            solution,
            mapf,
            neighborhood_agents,
            edge_weights_vec,
            spt_by_dest;
            conflict_price=conflict_price,
        )
        new_conflicts_count = count_conflicts(solution, mapf)
        if all_non_empty(solution) && new_conflicts_count < conflicts_count  # keep
            conflicts_count = new_conflicts_count
            steps_without_improvement = 0
        else  # revert
            for a in neighborhood_agents
                solution[a] = backup[a]
            end
            steps_without_improvement += 1
        end
        conflict_price *= (one(conflict_price_increase) + conflict_price_increase)
        if steps_without_improvement > max_steps_without_improvement
            break
        end
    end
    return solution
end

function feasibility_search(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec;
    neighborhood_size=10,
    conflict_price=1e-1,
    conflict_price_increase=1e-2,
    max_steps_without_improvement=100,
    show_progress=false,
)
    spt_by_dest = dijkstra_by_destination(
        mapf, edge_weights_vec; show_progress=show_progress
    )
    solution = independent_dijkstra_from_trees(mapf, spt_by_dest)
    feasibility_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_dest;
        neighborhood_size=neighborhood_size,
        conflict_price=conflict_price,
        conflict_price_increase=conflict_price_increase,
        max_steps_without_improvement=max_steps_without_improvement,
        show_progress=show_progress,
    )
    return solution
end
