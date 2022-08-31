function optimality_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec::AbstractVector{Int},
    shortest_path_trees::Dict;
    neighborhood_size,
    steps,
    show_progress,
)
    @assert is_feasible(solution, mapf)
    cost = flowtime(solution, mapf)
    p = Progress(steps; desc="Optimality search steps: ", enabled=show_progress)
    for _ in 1:steps
        next!(p)
        agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, agents, mapf)
        cooperative_astar!(solution, mapf, agents, edge_weights_vec, shortest_path_trees)
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

function optimality_search(
    mapf::MAPF,
    edge_weights_vec=mapf.edge_weights_vec,
    shortest_path_trees=dijkstra_to_destinations(mapf, edge_weights_vec);
    neighborhood_size=10,
    steps=100,
    show_progress=true,
)
    solution = cooperative_astar(
        mapf, randperm(nb_agents(mapf)), edge_weights_vec, shortest_path_trees
    )
    optimality_search!(
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
