function feasibility_search!(
    solution::Solution,
    mapf::MAPF,
    spt_by_arr::Dict{<:Integer,<:ShortestPathTree};
    feasibility_timeout,
    neighborhood_size,
    conflict_price,
    conflict_price_increase,
    show_progress,
    threaded=false,
)
    initial_conflicts_count = count_conflicts(solution, mapf)
    conflicts_count = initial_conflicts_count
    prog = ProgressUnknown(; desc="Feasibility search steps: ", enabled=show_progress)
    total_time = 0.0
    moves_tried = 0
    moves_successful = 0
    if is_individually_feasible(solution, mapf)
        while true
            moves_tried += 1
            τ1 = CPUtime_us()
            neighborhood_agents = random_neighborhood(mapf, neighborhood_size)
            backup_solution = remove_agents!(solution, neighborhood_agents)
            cooperative_astar!(
                SoftConflicts(),
                solution,
                mapf,
                neighborhood_agents,
                spt_by_arr;
                conflict_price,
            )
            new_conflicts_count = count_conflicts(solution, mapf)
            if (
                is_individually_feasible(solution, mapf) &&
                new_conflicts_count < conflicts_count
            )
                conflicts_count = new_conflicts_count
                moves_successful += 1
            else
                reinsert_agents!(solution, backup_solution)
            end
            τ2 = CPUtime_us()
            total_time += (τ2 - τ1) / 1e6
            if total_time > feasibility_timeout || conflicts_count == 0
                break
            else
                next!(prog; showvalues=[(:conflicts_count, conflicts_count)])
                conflict_price *= (1 + conflict_price_increase)
            end
        end
    end
    stats = Dict(
        :feasibility_moves_tried => moves_tried,
        :feasibility_moves_successful => moves_successful,
        :feasibility_initial_conflicts_count => initial_conflicts_count,
        :feasibility_final_conflicts_count => conflicts_count,
        :feasibility_feasible => is_feasible(solution, mapf),
        :feasibility_solution_cost => solution_cost(solution, mapf),
    )
    return stats
end

"""
$(TYPEDSIGNATURES)

Run [`independent_dijkstra`](@ref) and then reduce the number of conflicts with a variant of the MAPF-LNS2 algorithm from Li et al. (2022), see <https://ojs.aaai.org/index.php/AAAI/article/view/21266>.

Returns a tuple containing a `Solution` and a dictionary of statistics.
"""
function feasibility_search(
    mapf::MAPF;
    feasibility_timeout=2,
    neighborhood_size=10,
    conflict_price=1.0,
    conflict_price_increase=0.1,
    show_progress=false,
    threaded=false,
    spt_by_arr=dijkstra_by_arrival(mapf; show_progress, threaded),
)
    solution = independent_dijkstra(mapf; spt_by_arr, show_progress, threaded)
    stats = feasibility_search!(
        solution,
        mapf,
        spt_by_arr;
        feasibility_timeout,
        neighborhood_size,
        conflict_price,
        conflict_price_increase,
        show_progress,
        threaded,
    )
    return solution, stats
end
