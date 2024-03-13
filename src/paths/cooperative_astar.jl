function cooperative_astar_from_trees!(
    solution::Solution,
    mapf::MAPF,
    agents::AbstractVector{<:Integer},
    spt_by_arr::Dict{<:Integer,<:ShortestPathTree};
    show_progress=false,
)
    reservation = Reservation(solution, mapf)
    prog = Progress(length(agents); desc="Cooperative A*: ", enabled=show_progress)
    for a in agents
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        spt = spt_by_arr[arr]
        heuristic = spt.dists
        timed_path, stats = temporal_astar(
            mapf.g, mapf.edge_costs; a, dep, arr, tdep, reservation, heuristic
        )
        solution.timed_paths[a] = timed_path
        update_reservation!(reservation, timed_path, a, mapf)
        next!(prog)
    end
    return nothing
end

function cooperative_astar_soft_from_trees!(
    solution::Solution,
    mapf::MAPF,
    agents::AbstractVector{<:Integer},
    spt_by_arr::Dict{<:Integer,<:ShortestPathTree};
    conflict_price::Real,
    show_progress=false,
)
    reservation = Reservation(solution, mapf)
    prog = Progress(length(agents); desc="Cooperative A*: ", enabled=show_progress)
    for a in agents
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        spt = spt_by_arr[arr]
        heuristic = spt.dists
        timed_path, stats = temporal_astar_soft(
            mapf.g,
            mapf.edge_costs;
            a,
            dep,
            arr,
            tdep,
            reservation,
            heuristic,
            conflict_price,
        )
        solution.timed_paths[a] = timed_path
        update_reservation!(reservation, timed_path, a, mapf)
        next!(prog)
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Solve a MAPF problem `mapf` for a set of `agents` with the cooperative A* algorithm of Silver (2005), see <https://ojs.aaai.org/index.php/AIIDE/article/view/18726>.
The A* heuristic is given by [`independent_dijkstra`](@ref).

Returns a `Solution`.
"""
function cooperative_astar(
    mapf::MAPF, agents::AbstractVector{<:Integer}=1:nb_agents(mapf); show_progress=false
)
    spt_by_arr = dijkstra_by_arrival(mapf; show_progress)
    solution = Solution()
    cooperative_astar_from_trees!(solution, mapf, agents, spt_by_arr; show_progress)
    return solution
end
