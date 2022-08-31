function double_search(
    mapf::MAPF,
    edge_weights_vec::AbstractVector{<:Real}=mapf.edge_weights_vec;
    neighborhood_size=10,
    conflict_price=0.1,
    conflict_price_increase=1e-2,
    steps=100,
    show_progress=false,
)
    spt_by_dest = dijkstra_by_destination(mapf, edge_weights_vec)
    solution = independent_dijkstra(mapf, spt_by_dest)
    feasibility_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_dest;
        neighborhood_size=neighborhood_size,
        conflict_price=conflict_price,
        conflict_price_increase=conflict_price_increase,
        show_progress=show_progress,
    )
    optimality_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_dest;
        neighborhood_size=neighborhood_size,
        steps=steps,
        show_progress=show_progress,
    )
    return solution
end
