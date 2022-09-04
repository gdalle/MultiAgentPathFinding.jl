function dijkstra_by_arrival(
    mapf::MAPF, edge_weights_vec::AbstractVector{W}; show_progress=false
) where {W}
    w = build_weights_matrix(mapf, edge_weights_vec)
    unique_arrivals = unique(mapf.arrivals)
    K = length(unique_arrivals)
    spt_by_arr_vec = Vector{ShortestPathTree{Int,Union{Nothing,W}}}(undef, K)
    prog = Progress(K; desc="Dijkstra by destination: ", enabled=show_progress)
    @threads for k in 1:K
        next!(prog)
        spt_by_arr_vec[k] = backward_dijkstra(mapf.g, unique_arrivals[k], w)
    end
    spt_by_arr = Dict{Int,ShortestPathTree{Int,Union{Nothing,W}}}(
        unique_arrivals[k] => spt_by_arr_vec[k] for k in 1:K
    )
    return spt_by_arr
end

function independent_dijkstra_from_trees(mapf::MAPF, spt_by_arr)
    A = nb_agents(mapf)
    solution = Vector{TimedPath}(undef, A)
    for a in 1:A
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        timed_path = build_path_tree(spt_by_arr[arr], dep, arr, tdep)
        solution[a] = timed_path
    end
    return solution
end

function independent_dijkstra(
    mapf::MAPF, edge_weights_vec=mapf.edge_weights_vec; show_progress=false
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    return independent_dijkstra_from_trees(mapf, spt_by_arr)
end
