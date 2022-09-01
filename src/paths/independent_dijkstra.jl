function dijkstra_by_destination(
    mapf::MAPF, edge_weights_vec::AbstractVector{W}; show_progress=false
) where {W}
    (; g, arrivals) = mapf
    w = build_weights_matrix(mapf, edge_weights_vec)
    unique_arrivals = unique(arrivals)
    K = length(unique_arrivals)
    spt_by_dest_vec = Vector{ShortestPathTree{Int,Union{Nothing,W}}}(undef, K)
    prog = Progress(K; desc="Dijkstra by destination: ", enabled=show_progress)
    for k in 1:K
        next!(prog)
        spt_by_dest_vec[k] = backward_dijkstra(g, unique_arrivals[k], w)
    end
    spt_by_dest = Dict{Int,ShortestPathTree{Int,Union{Nothing,W}}}(
        unique_arrivals[k] => spt_by_dest_vec[k] for k in 1:K
    )
    return spt_by_dest
end

function independent_dijkstra_from_trees(mapf::MAPF, spt_by_dest)
    (; departures, arrivals, departure_times) = mapf
    A = nb_agents(mapf)
    solution = Vector{TimedPath}(undef, A)
    for a in 1:A
        s, d, t0 = departures[a], arrivals[a], departure_times[a]
        timed_path = build_timed_path(spt_by_dest[d], t0, s, d)
        solution[a] = timed_path
    end
    return solution
end

function independent_dijkstra(
    mapf::MAPF, edge_weights_vec=mapf.edge_weights_vec; show_progress=false
)
    spt_by_dest = dijkstra_by_destination(
        mapf, edge_weights_vec; show_progress=show_progress
    )
    return independent_dijkstra_from_trees(mapf, spt_by_dest)
end
