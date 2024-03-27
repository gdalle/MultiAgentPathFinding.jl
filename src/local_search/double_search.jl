"""
$(TYPEDSIGNATURES)

Combine [`feasibility_search`](@ref) and [`optimality_search`](@ref), see <https://pastel.hal.science/tel-04053322>.

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
    threaded=true,
    spt_by_arr=dijkstra_by_arrival(mapf; show_progress, threaded),
)
    # Feasibility search
    solution, feasibility_stats = feasibility_search(
        mapf;
        spt_by_arr,
        feasibility_timeout,
        neighborhood_size,
        conflict_price,
        conflict_price_increase,
        show_progress,
        threaded,
    )
    if !is_feasible(solution, mapf)
        solution = cooperative_astar(mapf, agents; spt_by_arr, show_progress, threaded)
    end
    # Optimality search
    optimality_stats = optimality_search!(
        solution,
        mapf,
        spt_by_arr;
        optimality_timeout,
        neighborhood_size,
        show_progress,
        threaded,
    )
    # Rename stats
    double_stats = merge(feasibility_stats, optimality_stats)
    renamed_double_stats = Dict((
        Symbol("double_" * string(key)) => val for (key, val) in pairs(double_stats)
    ))
    return solution, renamed_double_stats
end
