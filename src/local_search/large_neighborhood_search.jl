function large_neighborhood_search!(
    solution::Solution, mapf::MAPF; N=1, steps=10, progress=true
)
    @assert is_feasible(solution, mapf)
    cost = flowtime(solution, mapf)
    if progress
        p = Progress(steps; desc="LNS steps: ", enabled=progress)
    end
    for _ in 1:steps
        next!(p)
        agents = random_neighborhood(mapf, N)
        backup = remove_agents!(solution, agents)
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

function large_neighborhood_search(mapf::MAPF; N=1, steps=10, progress=true)
    solution = cooperative_astar(mapf, shuffle(1:nb_agents(mapf)))
    large_neighborhood_search!(solution, mapf; N=N, steps=steps, progress=progress)
    return solution
end
