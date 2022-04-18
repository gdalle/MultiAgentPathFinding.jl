function permutation_search(mapf::MAPF, initial_permutation)
    A = nb_agents(mapf)
    permutation = copy(initial_permutation)
    solution = cooperative_astar(mapf, permutation)
    indep_solution = independent_astar(mapf)
    cost = flowtime(solution, mapf)
    lower_bound = flowtime(indep_solution, mapf)
    improvement_found = true
    prog = ProgressUnknown("Local search steps:")
    while true
        gap = round(100 * (cost - lower_bound) / lower_bound; sigdigits=3)
        ProgressMeter.next!(prog; showvalues=[(:objective, cost), (:gap, gap)])
        improvement_found = false
        for i in shuffle(1:A), j in shuffle((i + 1):A)
            new_permutation = copy(permutation)
            new_permutation[i], new_permutation[j] = new_permutation[j], new_permutation[i]
            new_solution = cooperative_astar(mapf, new_permutation)
            new_cost = flowtime(new_solution, mapf)
            if new_cost < cost
                permutation = new_permutation
                cost = new_cost
                improvement_found = true
                break
            end
        end
        if !improvement_found
            ProgressMeter.finish!(prog)
            break
        end
    end
    final_solution = cooperative_astar(mapf, permutation)
    return final_solution
end
