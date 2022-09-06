function double_search(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec;
    feasibility_timeout=2,
    optimality_timeout=2,
    window=10,
    neighborhood_size=10,
    conflict_price=1e-1,
    conflict_price_increase=1e-1,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    solution = independent_dijkstra_from_trees(mapf, spt_by_arr)
    feasibility_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        feasibility_timeout=feasibility_timeout,
        window=window,
        neighborhood_size=neighborhood_size,
        conflict_price=conflict_price,
        conflict_price_increase=conflict_price_increase,
        show_progress=show_progress,
    )
    optimality_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        optimality_timeout=optimality_timeout,
        window=window,
        neighborhood_size=neighborhood_size,
        show_progress=show_progress,
    )
    return solution
end
