function large_neighborhood_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec::AbstractVector,
    shortest_path_trees::Dict;
    neighborhood_size::Integer,
    steps::Integer,
    show_progress::Bool=false,
)
    @assert is_feasible(solution, mapf)
    cost = flowtime(solution, mapf)
    p = Progress(steps; desc="LNS steps: ", enabled=show_progress)
    for _ in 1:steps
        next!(p)
        agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, agents, mapf)
        cooperative_astar!(solution, agents, mapf, edge_weights_vec, shortest_path_trees)
        new_cost = flowtime(solution, mapf)
        if is_feasible(solution, mapf) && new_cost < cost  # keep
            cost = new_cost
        else  # revert
            for a in agents
                solution[a] = backup[a]
            end
        end
    end
    return solution
end

function large_neighborhood_search(
    mapf::MAPF,
    edge_weights_vec::AbstractVector=mapf.edge_weights_vec,
    shortest_path_trees=dijkstra_to_destinations(mapf, edge_weights_vec);
    neighborhood_size=10,
    steps=10,
    show_progress=true,
)
    solution = cooperative_astar(
        mapf, 1:nb_agents(mapf), edge_weights_vec, shortest_path_trees
    )
    large_neighborhood_search!(
        solution,
        mapf,
        edge_weights_vec,
        shortest_path_trees;
        neighborhood_size=neighborhood_size,
        steps=steps,
        show_progress=show_progress,
    )
    return solution
end
