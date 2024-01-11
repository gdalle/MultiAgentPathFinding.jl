"""
$(SIGNATURES)

Combine `feasibility_search` and `optimality_search`, see <https://pastel.hal.science/tel-04053322>.

Returns a tuple containing a `Solution` and a dictionary of statistics.
"""
function double_search(
    mapf::MAPF,
    agents=1:nb_agents(mapf);
    feasibility_timeout=2,
    optimality_timeout=2,
    neighborhood_size=10,
    conflict_price=1.0,
    conflict_price_increase=0.1,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf; show_progress=show_progress)
    # Backup
    backup_solution = empty_solution(mapf)
    cooperative_astar_from_trees!(
        backup_solution, mapf, agents, spt_by_arr; show_progress=show_progress
    )
    # Feasibility search
    solution = independent_dijkstra_from_trees(mapf, spt_by_arr)
    feasibility_stats = feasibility_search!(
        solution,
        mapf,
        spt_by_arr;
        feasibility_timeout,
        neighborhood_size,
        conflict_price,
        conflict_price_increase,
        show_progress,
    )
    if !is_feasible(solution, mapf)
        solution = backup_solution
    end
    # Optimality search
    optimality_stats = optimality_search!(
        solution, mapf, spt_by_arr; optimality_timeout, neighborhood_size, show_progress
    )
    # Rename stats
    double_stats = merge(feasibility_stats, optimality_stats)
    renamed_double_stats = Dict((
        Symbol("double_" * string(key)) => val for (key, val) in pairs(double_stats)
    ))
    return solution, renamed_double_stats
end
