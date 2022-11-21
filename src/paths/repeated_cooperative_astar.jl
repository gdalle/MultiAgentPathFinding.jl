
"""
    repeated_cooperative_astar_from_trees(mapf, edge_weights_vec, spt_by_arr; coop_timeout)

Apply [`cooperative_astar_from_trees!`](@ref) repeatedly until a feasible solution is found or the timeout given by `coop_timeout` is reached.
"""
function repeated_cooperative_astar_from_trees(
    mapf::MAPF, edge_weights_vec, spt_by_arr; coop_timeout, show_progress=false
)
    prog = ProgressUnknown("Cooperative A* runs"; enabled=show_progress)
    total_time = 0.0
    while true
        τ1 = CPUtime_us()
        solution = empty_solution(mapf)
        agents = randperm(nb_agents(mapf))
        cooperative_astar_from_trees!(
            solution, mapf, agents, edge_weights_vec, spt_by_arr; show_progress=false
        )
        if is_feasible(solution, mapf)
            return solution
        end
        τ2 = CPUtime_us()
        total_time += (τ2 - τ1) / 1e6
        if total_time > coop_timeout
            break
        else
            next!(prog)
        end
    end
    return empty_solution(mapf)
end

"""
    repeated_cooperative_astar(mapf, edge_weights_vec; coop_timeout)

Compute a dictionary of [`ShortestPathTree`](@ref)s with [`dijkstra_by_arrival`](@ref), and then apply [`repeated_cooperative_astar_from_trees`](@ref).
"""
function repeated_cooperative_astar(
    mapf::MAPF, edge_weights_vec=mapf.edge_weights_vec; coop_timeout=2, show_progress=false
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    return repeated_cooperative_astar_from_trees(
        mapf,
        edge_weights_vec,
        spt_by_arr;
        coop_timeout=coop_timeout,
        show_progress=show_progress,
    )
end
