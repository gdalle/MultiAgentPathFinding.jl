function independent_astar(
    mapf::MAPF, edge_weights_vec::AbstractVector=mapf.edge_weights_vec; show_progress=false
)
    (;
        graph,
        edge_indices,
        sources,
        destinations,
        starting_times,
        distances_to_destinations,
    ) = mapf
    A = nb_agents(mapf)
    solution = Vector{TimedPath}(undef, A)
    prog = Progress(A; enabled=show_progress)
    for a in 1:A
        next!(prog)
        s, d, t0 = sources[a], destinations[a], starting_times[a]
        dist = distances_to_destinations[d]
        heuristic(v) = dist[v]
        solution[a] = temporal_astar(
            graph, s, d, t0, edge_indices, edge_weights_vec; heuristic=heuristic
        )
    end
    return solution
end
