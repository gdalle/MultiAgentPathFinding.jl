"""
    double_search(
        mapf, edge_weights_vec;
        feasibility_timeout, optimality_timeout, window,
        neighborhood_size, conflict_price, conflict_price_increase
    )

Initialize a `Solution` with [`independent_dijkstra`](@ref), then apply [`feasibility_search!`] to make it feasible, followed by [`optimality_search!`](@ref) to reduce its flowtime.
"""
function double_search(
    mapf::MAPF,
    agents=1:nb_agents(mapf),
    edge_weights_vec=mapf.edge_weights_vec;
    feasibility_timeout=2,
    optimality_timeout=2,
    neighborhood_size=10,
    conflict_price=1.0,
    conflict_price_increase=0.1,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    backup_solution = empty_solution(mapf)
    cooperative_astar_from_trees!(
        backup_solution,
        mapf,
        agents,
        edge_weights_vec,
        spt_by_arr;
        show_progress=show_progress,
    )
    solution = independent_dijkstra_from_trees(mapf, spt_by_arr)
    feasibility_stats = feasibility_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        feasibility_timeout=feasibility_timeout,
        neighborhood_size=neighborhood_size,
        conflict_price=conflict_price,
        conflict_price_increase=conflict_price_increase,
        show_progress=show_progress,
    )
    feasibility_success = is_feasible(solution, mapf)
    if !feasibility_success
        solution = backup_solution
    end
    optimality_stats = optimality_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        optimality_timeout=optimality_timeout,
        neighborhood_size=neighborhood_size,
        show_progress=show_progress,
    )
    double_stats = merge(
        feasibility_stats, (feasibility_success=feasibility_success,), optimality_stats
    )
    return solution, double_stats
end
