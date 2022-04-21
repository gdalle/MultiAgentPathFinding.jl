function update_forbidden_vertices!(forbidden_vertices, path::Path, mapf::MAPF)
    for (t, v) in path
        for g in mapf.group_memberships[v]
            for w in mapf.conflict_groups[g]
                push!(forbidden_vertices, (t, w))
            end
        end
    end
    return nothing
end

function compute_forbidden_vertices(solution::Solution, mapf::MAPF)
    forbidden_vertices = Reservation()
    for a in 1:nb_agents(mapf)
        path = solution[a]
        update_forbidden_vertices!(forbidden_vertices, path, mapf::MAPF)
    end
    return forbidden_vertices
end

function cooperative_astar!(solution::Solution, agents, mapf::MAPF)
    forbidden_vertices = compute_forbidden_vertices(solution, mapf)
    graph, edge_weights = mapf.graph, mapf.edge_weights
    @showprogress for a in agents
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

function cooperative_astar(mapf::MAPF, permutation=1:nb_agents(mapf))
    solution = [Path() for a in 1:nb_agents(mapf)]
    cooperative_astar!(solution, permutation, mapf)
    return solution
end
