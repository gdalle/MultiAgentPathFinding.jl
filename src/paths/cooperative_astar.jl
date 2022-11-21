"""
    cooperative_astar_from_trees!(solution, mapf, agents, edge_weights_vec, spt_by_arr)

Modify a `Solution` by applying [`temporal_astar`](@ref) to a subset of agents while avoiding conflicts thanks to a `Reservation`.

# Arguments

- `agents`: subset of agents taken in order
- `edge_weights_vec`: edge weights stored as a vector
- `spt_by_arr`: dictionary of [`ShortestPathTree`](@ref)s, one for each arrival vertex
"""
function cooperative_astar_from_trees!(
    solution::Solution,
    mapf::MAPF{G},
    agents,
    edge_weights_vec::AbstractVector{W},
    spt_by_arr;
    show_progress=false,
) where {G,W}
    w = build_weights_matrix(mapf, edge_weights_vec)
    res = compute_reservation(solution, mapf)
    prog = Progress(length(agents); desc="Cooperative A*: ", enabled=show_progress)
    for a in agents
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        flexible_departure = mapf.flexible_departure
        spt = spt_by_arr[arr]
        tmax = max(max_time(res), tdep) + path_length_tree(spt, dep, arr)
        heuristic(v) = spt.dists[v]
        timed_path = temporal_astar(
            mapf.g,
            w;
            dep=dep,
            arr=arr,
            tdep=tdep,
            tmax=tmax,
            res=res,
            heuristic=heuristic,
            flexible_departure=flexible_departure,
        )
        solution[a] = timed_path
        update_reservation!(res, timed_path, mapf, a)
        next!(prog)
    end
    return nothing
end

"""
    cooperative_astar_from_trees_soft!(solution, mapf, agents, edge_weights_vec, spt_by_arr)

Does the same things as [`cooperative_astar_from_trees!`](@ref) but with [`temporal_astar_soft`](@ref) as a basic subroutine.

# Arguments

- `agents`, `edge_weights`, `spt_by_arr`: see [`cooperative_astar_from_trees!`](@ref)
- `conflict_price`: see [`temporal_astar_soft`](@ref)
"""
function cooperative_astar_soft_from_trees!(
    solution::Solution,
    mapf::MAPF,
    agents,
    edge_weights_vec::AbstractVector{W},
    spt_by_arr;
    conflict_price,
    show_progress=false,
) where {W}
    w = build_weights_matrix(mapf, edge_weights_vec)
    res = compute_reservation(solution, mapf)
    prog = Progress(length(agents); desc="Cooperative A*: ", enabled=show_progress)
    for a in agents
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        spt = spt_by_arr[arr]
        tmax = max(max_time(res), tdep) + path_length_tree(spt, dep, arr)
        flexible_departure = mapf.flexible_departure
        heuristic(v) = spt.dists[v]
        timed_path = temporal_astar_soft(
            mapf.g,
            w;
            dep=dep,
            arr=arr,
            tdep=tdep,
            tmax=tmax,
            res=res,
            heuristic=heuristic,
            conflict_price=conflict_price,
            flexible_departure=flexible_departure,
        )
        solution[a] = timed_path
        update_reservation!(res, timed_path, mapf, a)
        next!(prog)
    end
    return nothing
end

"""
    cooperative_astar(solution, mapf, agents, edge_weights_vec, spt_by_arr)

Create an empty `Solution`, a dictionary of [`ShortestPathTree`](@ref)s and apply [`cooperative_astar_from_trees!`](@ref).
"""
function cooperative_astar(
    mapf::MAPF,
    agents=1:nb_agents(mapf),
    edge_weights_vec=mapf.edge_weights_vec;
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    solution = empty_solution(mapf)
    cooperative_astar_from_trees!(
        solution, mapf, agents, edge_weights_vec, spt_by_arr; show_progress=show_progress
    )
    return solution
end
