"""
    feasibility_search!(
        solution, mapf, edge_weights_vec, spt_by_arr;
        feasibility_timeout, window,
        neighborhood_size, conflict_price, conflict_price_increase
    )

Reduce the number of conflicts in an infeasible `Solution` with a variant of the MAPF-LNS2 algorithm from Li et al. (2022).
"""
function feasibility_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec,
    spt_by_arr;
    feasibility_timeout,
    window,
    neighborhood_size,
    conflict_price,
    conflict_price_increase,
    show_progress,
)
    is_individually_feasible(solution, mapf) || return solution
    conflicts_count = count_conflicts(solution, mapf)
    prog = ProgressUnknown("Feasibility search steps: "; enabled=show_progress)
    total_time = 0.0
    while true
        τ1 = CPUtime_us()
        neighborhood_agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, neighborhood_agents, mapf)
        cooperative_astar_soft_from_trees!(
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
        )
            conflicts_count = new_conflicts_count
        else
            for a in neighborhood_agents
                solution[a] = backup[a]
            end
        end
        τ2 = CPUtime_us()
        total_time += (τ2 - τ1) / 1e6
        if total_time > feasibility_timeout || conflicts_count == 0
            break
        else
            next!(prog; showvalues=[(:conflicts_count, conflicts_count)])
            conflict_price *= (one(conflict_price_increase) + conflict_price_increase)
        end
    end
    return solution
end

"""
    feasibility_search(
        mapf, edge_weights_vec;
        feasibility_timeout, window,
        neighborhood_size, conflict_price, conflict_price_increase
    )

Initialize a `Solution` with [`independent_dijkstra`](@ref), and then apply [`feasibility_search!`](@ref) to reduce the number of conflicts.
"""
function feasibility_search(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec;
    feasibility_timeout=2,
    window=10,
    neighborhood_size=10,
    conflict_price=1e-1,
    conflict_price_increase=1e-1,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    solution = independent_dijkstra_from_trees(mapf, spt_by_arr)
    feasibility_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        feasibility_timeout=feasibility_timeout,
        window=window,
        neighborhood_size=neighborhood_size,
        conflict_price=conflict_price,
        conflict_price_increase=conflict_price_increase,
        show_progress=show_progress,
    )
    return solution
end
