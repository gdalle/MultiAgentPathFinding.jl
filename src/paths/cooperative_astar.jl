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
$(SIGNATURES)

Solve a MAPF problem with the cooperative A* algorithm of Silver (2005), see <https://ojs.aaai.org/index.php/AIIDE/article/view/18726>.

Returns a `Solution`.
"""
function cooperative_astar(mapf::MAPF, agents=1:nb_agents(mapf); show_progress=false)
    spt_by_arr = dijkstra_by_arrival(mapf; show_progress)
    solution = empty_solution(mapf)
    cooperative_astar_from_trees!(solution, mapf, agents, spt_by_arr; show_progress)
    return solution
end

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
$(SIGNATURES)

Repeat `cooperative_astar` with random permutations until a feasible solution is found or `coop_timeout` is reached.

Returns a `Solution`.
"""
function repeated_cooperative_astar(mapf::MAPF; coop_timeout=2, show_progress=false)
    spt_by_arr = dijkstra_by_arrival(mapf; show_progress)
    solution = repeated_cooperative_astar_from_trees(
        mapf, spt_by_arr; coop_timeout, show_progress
    )
    return solution
end
