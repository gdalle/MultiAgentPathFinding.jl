"""
    cooperative_astar_from_trees!(solution, mapf, agents, spt_by_arr)

Modify a `Solution` by applying [`temporal_astar`](@ref) to a subset of agents while avoiding conflicts thanks to a `Reservation`.

# Arguments

- `agents`: subset of agents taken in order
- `spt_by_arr`: dictionary of [`ShortestPathTree`](@ref)s, one for each arrival vertex
"""
function cooperative_astar_from_trees!(
    solution::Solution, mapf::MAPF, agents, spt_by_arr; show_progress=false
)
    res = compute_reservation(solution, mapf)
    prog = Progress(length(agents); desc="Cooperative A*: ", enabled=show_progress)
    for a in agents
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        spt = spt_by_arr[arr]
        tmax = max(max_time(res), tdep) + path_length_tree(spt, dep, arr)  # TODO: param
        heuristic = spt.dists
        timed_path = temporal_astar(
            mapf.g, mapf.edge_weights; dep, arr, tdep, tmax, res, heuristic
        )
        solution[a] = timed_path
        update_reservation!(res, timed_path, mapf, a)
        next!(prog)
    end
    return nothing
end

"""
    cooperative_astar_from_trees_soft!(solution, mapf, agents, spt_by_arr)

Does the same things as [`cooperative_astar_from_trees!`](@ref) but with [`temporal_astar_soft`](@ref) as a basic subroutine.

# Arguments

- `agents`, `spt_by_arr`: see [`cooperative_astar_from_trees!`](@ref)
- `conflict_price`: see [`temporal_astar_soft`](@ref)
"""
function cooperative_astar_soft_from_trees!(
    solution::Solution, mapf::MAPF, agents, spt_by_arr; conflict_price, show_progress=false
)
    res = compute_reservation(solution, mapf)
    prog = Progress(length(agents); desc="Cooperative A*: ", enabled=show_progress)
    for a in agents
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        spt = spt_by_arr[arr]
        tmax = max(max_time(res), tdep) + path_length_tree(spt, dep, arr)  # TODO: param
        heuristic = spt.dists
        timed_path = temporal_astar_soft(
            mapf.g, mapf.edge_weights; dep, arr, tdep, tmax, res, heuristic, conflict_price
        )
        solution[a] = timed_path
        update_reservation!(res, timed_path, mapf, a)
        next!(prog)
    end
    return nothing
end

"""
    cooperative_astar(solution, mapf, agents, spt_by_arr)

Create an empty `Solution`, a dictionary of [`ShortestPathTree`](@ref)s and apply [`cooperative_astar_from_trees!`](@ref).
"""
function cooperative_astar(mapf::MAPF, agents=1:nb_agents(mapf), show_progress=false)
    spt_by_arr = dijkstra_by_arrival(mapf; show_progress)
    solution = empty_solution(mapf)
    cooperative_astar_from_trees!(solution, mapf, agents, spt_by_arr; show_progress)
    return solution
end

"""
    repeated_cooperative_astar_from_trees(mapf, spt_by_arr; coop_timeout)

Apply [`cooperative_astar_from_trees!`](@ref) repeatedly until a feasible solution is found or the timeout given by `coop_timeout` is reached.
"""
function repeated_cooperative_astar_from_trees(
    mapf::MAPF, spt_by_arr; coop_timeout, show_progress=false
)
    prog = ProgressUnknown(; desc="Cooperative A* runs", enabled=show_progress)
    total_time = 0.0
    while true
        τ1 = CPUtime_us()
        solution = empty_solution(mapf)
        agents = randperm(nb_agents(mapf))
        cooperative_astar_from_trees!(
            solution, mapf, agents, spt_by_arr; show_progress=false
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
    repeated_cooperative_astar(mapf; coop_timeout)

Compute a dictionary of [`ShortestPathTree`](@ref)s with [`dijkstra_by_arrival`](@ref), and then apply [`repeated_cooperative_astar_from_trees`](@ref).
"""
function repeated_cooperative_astar(mapf::MAPF; coop_timeout=2, show_progress=false)
    spt_by_arr = dijkstra_by_arrival(mapf; show_progress)
    return repeated_cooperative_astar_from_trees(
        mapf, spt_by_arr; coop_timeout, show_progress
    )
end
