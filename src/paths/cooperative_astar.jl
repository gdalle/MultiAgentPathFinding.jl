function cooperative_astar!(
    solution::Solution,
    mapf::MAPF,
    agents::AbstractVector{<:Integer},
    spt_by_arr::Dict{<:Integer,<:ShortestPathTree};
    kwargs...,
)
    return cooperative_astar!(
        HardConflicts(), solution, mapf, agents, spt_by_arr; kwargs...
    )
end

function cooperative_astar!(
    c::ConflictHandling,
    solution::Solution,
    mapf::MAPF,
    agents::AbstractVector{<:Integer},
    spt_by_arr::Dict{<:Integer,<:ShortestPathTree};
    show_progress=false,
    kwargs...,
)
    (; g, edge_costs) = mapf
    reservation = Reservation(solution, mapf)
    prog = Progress(length(agents); desc="Cooperative A*: ", enabled=show_progress)
    for a in agents
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        spt = spt_by_arr[arr]
        heuristic = spt.dists
        timed_path, stats = temporal_astar(
            c, g, edge_costs; a, dep, arr, tdep, reservation, heuristic, kwargs...
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
    mapf::MAPF,
    agents::AbstractVector{<:Integer}=1:nb_agents(mapf);
    show_progress=false,
    threaded=false,
    spt_by_arr=dijkstra_by_arrival(mapf; show_progress, threaded),
)
    solution = Solution()
    cooperative_astar!(HardConflicts(), solution, mapf, agents, spt_by_arr; show_progress)
    return solution
end
