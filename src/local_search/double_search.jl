function double_search(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec;
    neighborhood_size=10,
    conflict_price=1e-1,
    conflict_price_increase=1e-2,
    max_steps_without_improvement=1000,
    show_progress=false,
)
    spt_by_dest = dijkstra_by_destination(
        mapf, edge_weights_vec; show_progress=show_progress
    )
    solution = independent_dijkstra_from_trees(mapf, spt_by_dest)
    feasibility_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_dest;
        neighborhood_size=neighborhood_size,
        conflict_price=conflict_price,
        conflict_price_increase=conflict_price_increase,
        max_steps_without_improvement=max_steps_without_improvement,
        show_progress=show_progress,
    )
    optimality_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_dest;
        neighborhood_size=neighborhood_size,
        max_steps_without_improvement=max_steps_without_improvement,
        show_progress=show_progress,
    )
    return solution
end
