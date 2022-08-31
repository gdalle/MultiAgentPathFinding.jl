function dijkstra_by_destination(
    mapf::MAPF, edge_weights_vec::AbstractVector{W}; show_progress=false
) where {W}
    (; g, destinations) = mapf
    w = build_weights_matrix(mapf, edge_weights_vec)
    unique_destinations = unique(destinations)
    K = length(unique_destinations)
    spt_by_dest_vec = Vector{ShortestPathTree{Int,Union{Nothing,W}}}(undef, K)
    prog = Progress(K; desc="Dijkstra by destination: ", enabled=show_progress)
    for k in 1:K
        next!(prog)
        spt_by_dest_vec[k] = backward_dijkstra(g, unique_destinations[k], w)
    end
    spt_by_dest = Dict{Int,ShortestPathTree{Int,Union{Nothing,W}}}(
        unique_destinations[k] => spt_by_dest_vec[k] for k in 1:K
    )
    return spt_by_dest
end

function independent_dijkstra(mapf::MAPF, spt_by_dest::Dict{Int,<:ShortestPathTree})
    (; sources, destinations, departure_times) = mapf
    A = nb_agents(mapf)
    solution = Vector{TimedPath}(undef, A)
    for a in 1:A
        s, d, t0 = sources[a], destinations[a], departure_times[a]
        solution[a] = build_timed_path(spt_by_dest[d], t0, s, d)
    end
    return solution
end

function independent_dijkstra(
    mapf::MAPF,
    edge_weights_vec::AbstractVector{<:Real}=mapf.edge_weights_vec;
    show_progress=false,
)
    spt_by_dest = dijkstra_by_destination(
        mapf, edge_weights_vec; show_progress=show_progress
    )
    return independent_dijkstra(mapf, spt_by_dest)
end
