function optimality_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec::AbstractVector{<:Real},
    spt_by_dest::Dict{Int,<:ShortestPathTree};
    neighborhood_size,
    steps,
    show_progress,
)
    @assert is_feasible(solution, mapf)
    cost = flowtime(solution, mapf)
    prog = Progress(steps; desc="Optimality search steps: ", enabled=show_progress)
    for _ in 1:steps
        next!(prog)
        agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, agents, mapf)
        cooperative_astar!(solution, mapf, agents, edge_weights_vec, spt_by_dest;)
        new_cost = flowtime(solution, mapf)
        if all_non_empty(solution) && new_cost < cost  # keep, non-emptyness after A* ensures feasibility
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
    edge_weights_vec::AbstractVector{<:Real}=mapf.edge_weights_vec;
    neighborhood_size=10,
    steps=100,
    show_progress=false,
)
    agents = randperm(nb_agents(mapf))
    spt_by_dest = dijkstra_by_destination(mapf, edge_weights_vec; show_progress=false)
    solution = cooperative_astar(mapf, agents, edge_weights_vec, spt_by_dest;)
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
