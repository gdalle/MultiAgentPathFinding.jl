function independent_astar(
    mapf::MAPF, edge_weights::AbstractVector=mapf.edge_weights; show_progress=false
)
    A = nb_agents(mapf)
    solution = Vector{Path}(undef, A)
    prog = Progress(A; enabled=show_progress)
    for a in 1:A
        next!(prog)
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        solution[a] = temporal_astar(
            mapf.graph,
            s,
            d,
            t0;
            edge_indices=mapf.edge_indices,
            edge_weights=edge_weights,
            heuristic=heuristic,
        )
    end
    return solution
end

function independent_astar(
    mapf::MAPF,
    constraints,
    edge_weights::AbstractVector=mapf.edge_weights;
    show_progress=false,
)
    A = nb_agents(mapf)
    solution = Vector{Path}(undef, A)
    prog = Progress(A; enabled=show_progress)
    for a in 1:A
        next!(prog)
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        solution[a] = temporal_astar(
            mapf.graph,
            s,
            d,
            t0;
            edge_indices=mapf.edge_indices,
            edge_weights=edge_weights,
            reservation=constraints[a],
            heuristic=heuristic,
        )
    end
    return solution
end
