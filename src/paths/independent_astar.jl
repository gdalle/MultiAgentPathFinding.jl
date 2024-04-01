"""
$(TYPEDSIGNATURES)

Compute independent _temporal_ shortest paths for each agent of `mapf`.

Returns a [`Solution`](@ref).
"""
function independent_astar(
    mapf::MAPF,
    agents::AbstractVector{<:Integer}=1:nb_agents(mapf);
    show_progress=false,
    threaded=false,
    spt_by_arr=dijkstra_by_arrival(mapf; show_progress, threaded),
)
    (; g, edge_costs) = mapf
    solution = Solution()
    reservation = Reservation()
    prog = Progress(length(agents); desc="Independent A* by agent: ", enabled=show_progress)
    if threaded
        tforeach(agents) do a
            solution.timed_paths[a] = temporal_astar(
                IgnoredConflicts(),
                g,
                edge_costs;
                a=a,
                dep=mapf.departures[a],
                arr=mapf.arrivals[a],
                tdep=mapf.departure_times[a],
                reservation=reservation,
                heuristic=spt_by_arr[mapf.arrivals[a]].dists,
            )[1]
            next!(prog)
        end
    else
        foreach(agents) do a
            solution.timed_paths[a] = temporal_astar(
                IgnoredConflicts(),
                g,
                edge_costs;
                a=a,
                dep=mapf.departures[a],
                arr=mapf.arrivals[a],
                tdep=mapf.departure_times[a],
                reservation=reservation,
                heuristic=spt_by_arr[mapf.arrivals[a]].dists,
            )[1]
            next!(prog)
        end
    end
    return solution
end
