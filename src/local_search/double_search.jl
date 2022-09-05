function double_search(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec;
    window=10,
    neighborhood_size=10,
    conflict_price=1e-1,
    conflict_price_increase=1e-2,
    feasibility_max_stagnation=100,
    optimality_max_stagnation=100,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf, edge_weights_vec; show_progress=show_progress)
    solution = independent_dijkstra_from_trees(mapf, spt_by_arr)
    feasibility_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        window=window,
        neighborhood_size=neighborhood_size,
        conflict_price=conflict_price,
        conflict_price_increase=conflict_price_increase,
        max_stagnation=feasibility_max_stagnation,
        show_progress=show_progress,
    )
    optimality_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_arr;
        window=window,
        neighborhood_size=neighborhood_size,
        max_stagnation=optimality_max_stagnation,
        show_progress=show_progress,
    )
    return solution
end
