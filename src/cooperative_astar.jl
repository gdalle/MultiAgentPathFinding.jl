function update_forbidden_vertices!(forbidden_vertices, path, mapf)
    for (t, v) in path
        for g in mapf.group_memberships[v]
            for w in mapf.conflict_groups[g]
                push!(forbidden_vertices, (t, w))
            end
        end
    end
    return nothing
end

function compute_forbidden_vertices(solution, mapf)
    forbidden_vertices = Reservation()
    for a in 1:nb_agents(mapf)
        path = solution[a]
        update_forbidden_vertices!(forbidden_vertices, path, mapf)
    end
    return forbidden_vertices
end

function cooperative_astar!(solution, agents, mapf)
    forbidden_vertices = compute_forbidden_vertices(solution, mapf)
    graph, edge_weights = mapf.graph, mapf.edge_weights
    for a in agents
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        path = temporal_astar(
            graph,
            s,
            d,
            t0;
            edge_weights=edge_weights,
            heuristic=heuristic,
            forbidden_vertices=forbidden_vertices,
        )
        solution[a] = path
        update_forbidden_vertices!(forbidden_vertices, path, mapf)
    end
end

function cooperative_astar(mapf, permutation)
    solution = [Path() for a in 1:nb_agents(mapf)]
    cooperative_astar!(solution, permutation, mapf)
    return solution
end

function local_search_permutations(mapf, initial_permutation)
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

function feasibility_search!(solution, mapf)
    A = nb_agents(mapf)
    pathless_agents = shuffle([a for a in 1:A if length(solution[a]) == 0])
    cooperative_astar!(solution, pathless_agents, mapf)
    conflict_count = [nb_conflicts(solution, a, mapf) for a = 1:A]
    prog = ProgressUnknown("Feasibility search steps: ")
    while sum(conflict_count) > 0
        ProgressMeter.next!(prog, showvalues=[(:number_of_conflicts, sum(conflict_count))])
        a = argmax(conflict_count)
        cooperative_astar!(solution, [a], mapf)
        for b = 1:A
            conflict_count[b] = nb_conflicts(solution, b, mapf)
        end
    end
    return solution
end
