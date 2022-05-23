function large_neighborhood_search!(
    solution::Solution,
    mapf::MAPF;
    neighborhood_size::Integer,
    steps::Integer,
    progress::Bool=false,
)
    @assert is_feasible(solution, mapf)
    cost = flowtime(solution, mapf)
    p = Progress(steps; desc="LNS steps: ", enabled=progress)
    for _ in 1:steps
        next!(p)
        agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, agents, mapf)
        cooperative_astar!(solution, agents, mapf)
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
    mapf::MAPF; neighborhood_size=10, steps=10, progress=true
)
    solution = cooperative_astar(mapf, shuffle(1:nb_agents(mapf)))
    large_neighborhood_search!(
        solution, mapf; neighborhood_size=neighborhood_size, steps=steps, progress=progress
    )
    return solution
end
