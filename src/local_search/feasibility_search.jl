function feasibility_search!(solution::Solution, mapf::MAPF)
    A = nb_agents(mapf)
    pathless_agents = shuffle([a for a in 1:A if length(solution[a]) == 0])
    cooperative_astar!(solution, pathless_agents, mapf)
    conflict_count = [count_conflicts(a, solution, mapf) for a = 1:A]
    prog = ProgressUnknown("Feasibility search steps: ")
    while sum(conflict_count) > 0
        ProgressMeter.next!(prog, showvalues=[(:number_of_conflicts, sum(conflict_count))])
        a = argmax(conflict_count)
        cooperative_astar!(solution, [a], mapf)
        for b = 1:A
            conflict_count[b] = count_conflicts(b, solution, mapf)
        end
    end
    return solution
end

function large_neighborhood_search2!(solution::Solution, mapf::MAPF; N=1)
    A = nb_agents(mapf)
    pathless_agents = shuffle([a for a in 1:A if length(solution[a]) == 0])
    cooperative_SIPPS!(solution, mapf; agents=pathless_agents)
    cp = colliding_pairs(solution, mapf)
    prog = ProgressUnknown("LNS2 steps: ")
    # while !is_feasible(solution, mapf)
    for k = 1:5
        next!(prog, showvalues=[(:colliding_pairs, cp)])
        neighborhood_agents = random_neighborhood_collision_degree(solution, mapf, N)
        backup = remove_agents!(solution, neighborhood_agents)
        cooperative_SIPPS!(solution, mapf; agents=neighborhood_agents)
        new_cp = colliding_pairs(solution, mapf)
        @info "Comparison" cp new_cp
        if is_feasible(solution, mapf) || (new_cp <= cp)  # keep
            cp = new_cp
        else  # revert
            for a in neighborhood_agents
                solution[a] = backup[a]
            end
        end
    end
    return solution
end

function large_neighborhood_search2(mapf::MAPF; N=1)
    solution = independent_dijkstra(mapf)
    large_neighborhood_search2!(solution, mapf; N=N)
    return solution
end
