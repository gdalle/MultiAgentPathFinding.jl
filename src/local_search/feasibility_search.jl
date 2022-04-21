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
