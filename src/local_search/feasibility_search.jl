function feasibility_search!(
    solution::Solution,
    mapf::MAPF;
    neighborhood_size=1,
    conflict_price=Inf,
    conflict_price_increase=0.0,
    progress=true,
)
    A = nb_agents(mapf)
    pathless_agents = shuffle([a for a in 1:A if length(solution[a]) == 0])
    cooperative_astar!(solution, pathless_agents, mapf; conflict_price=conflict_price)
    cp = colliding_pairs(solution, mapf)
    prog = ProgressUnknown("LNS2 steps: "; enabled=progress)
    while !is_feasible(solution, mapf)
        next!(prog; showvalues=[(:colliding_pairs, cp)])
        neighborhood_agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, neighborhood_agents)
        cooperative_astar!(
            solution, neighborhood_agents, mapf; conflict_price=conflict_price
        )
        new_cp = colliding_pairs(solution, mapf)
        if is_feasible(solution, mapf) || (new_cp <= cp)  # keep
            cp = new_cp
        else  # revert
            for a in neighborhood_agents
                solution[a] = backup[a]
            end
        end
        conflict_price *= (1 + conflict_price_increase)
    end
    return solution
end

function feasibility_search(
    mapf::MAPF;
    neighborhood_size=1,
    conflict_price=Inf,
    conflict_price_increase=0.0,
    progress=true,
)
    solution = independent_dijkstra(mapf)
    feasibility_search!(
        solution,
        mapf;
        neighborhood_size=neighborhood_size,
        conflict_price=conflict_price,
        conflict_price_increase=conflict_price_increase,
        progress=progress,
    )
    return solution
end
