"""
    optimality_search!(
        solution, mapf, edge_weights_vec, spt_by_arr;
        optimality_timeout, neighborhood_size
    )

Reduce the flowtime of a feasible `Solution` with the MAPF-LNS algorithm from Li et al. (2021).
"""
function optimality_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec,
    spt_by_arr;
    optimality_timeout,
    neighborhood_size,
    show_progress,
)
    is_feasible(solution, mapf) || return solution
    initial_cost = flowtime(solution, mapf)
    cost = initial_cost
    prog = ProgressUnknown("Optimality search steps: "; enabled=show_progress)
    total_time = 0.0
    moves_tried = 0
    moves_successful = 0
    while true
        moves_tried += 1
        τ1 = CPUtime_us()
        neighborhood_agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, neighborhood_agents, mapf)
        cooperative_astar_from_trees!(
            solution, mapf, neighborhood_agents, edge_weights_vec, spt_by_arr;
        )
        new_cost = flowtime(solution, mapf)
        if is_individually_feasible(solution, mapf) && new_cost < cost
            cost = new_cost
            moves_successful += 1
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
    stats = (
        optimality_moves_tried=moves_tried,
        optimality_moves_successful=moves_successful,
        optimality_initial_cost=initial_cost,
        optimality_final_cost=cost,
    )
    return stats
end

"""
    optimality_search(
        mapf, agents, edge_weights_vec, spt_by_arr;
        optimality_timeout, neighborhood_size
    )

Initialize a `Solution` with [`cooperative_astar`](@ref), and then apply [`optimality_search!`](@ref) to reduce its flowtime.
"""
function optimality_search(
    mapf::MAPF,
    agents=1:nb_agents(mapf),
    edge_weights_vec=mapf.edge_weights_vec;
    optimality_timeout=2,
    neighborhood_size=10,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    solution = empty_solution(mapf)
    cooperative_astar_from_trees!(
        solution, mapf, agents, edge_weights_vec, spt_by_arr; show_progress=show_progress
    )
    stats = optimality_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        optimality_timeout=optimality_timeout,
        neighborhood_size=neighborhood_size,
        show_progress=show_progress,
    )
    return solution, stats
end
