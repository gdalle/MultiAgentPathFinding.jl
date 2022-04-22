function independent_dijkstra(mapf::MAPF; edge_weights=mapf.edge_weights)
    @assert minimum(findnz(edge_weights)[3]) >= -eps()
    A = nb_agents(mapf)
    unique_destinations = unique(mapf.destinations)
    dijkstra_states = Dict()
    for d in unique_destinations
        dijkstra_states[d] = dijkstra_shortest_paths(mapf.rev_graph, d, edge_weights')
    end
    solution = Vector{Path}(undef, A)
    for a in 1:A
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        parents = dijkstra_states[d].parents
        t, v = t0, s
        path = [(t, v)]
        while v != d
            v = parents[v]
            t += 1
            push!(path, (t, v))
        end
        solution[a] = path
    end
    return solution
end

function independent_topological_sort(mapf::MAPF; T, edge_weights=mapf.edge_weights)
    rev_g = mapf.rev_graph
    rev_edge_weights = Matrix(edge_weights')

    V = nv(rev_g)
    A = nb_agents(mapf)

    solution = Vector{Path}(undef, A)
    dists = OffsetMatrix{Float64}(undef, 0:T, V)
    parents = Matrix{Int}(undef, T, V)

    for d in unique(mapf.destinations)
        for v in vertices(rev_g)
            dists[0, v] = v == d ? 0.0 : Inf
        end
        for t in 1:T, v in 1:V
            dists[t, v] = Inf
            parents[t, v] = 0
            for u in inneighbors(rev_g, v)
                dist_du = dists[t - 1, u]
                weight_uv = rev_edge_weights[u, v]
                if dist_du + weight_uv < dists[t, v]
                    dists[t, v] = dist_du + weight_uv
                    parents[t, v] = u
                end
            end
        end
        for a in 1:A
            mapf.destinations[a] == d || continue
            s = mapf.sources[a]
            t0 = mapf.starting_times[a]
            tf = minimum(t for t = 1:T if dists[t, s] < Inf)
            t, v = tf, s
            path = [(t0 + tf - t, v)]
            while v != d
                v = parents[t, v]
                t -= 1
                push!(path, (t0 + tf - t, v))
            end
            solution[a] = path
        end
    end
    return solution
end

function independent_astar(mapf::MAPF)
    graph, edge_weights = mapf.graph, mapf.edge_weights
    A = nb_agents(mapf)
    solution = Vector{Path}(undef, A)
    for a in 1:A
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        solution[a] = temporal_astar(
            graph, s, d, t0; edge_weights=edge_weights, heuristic=heuristic
        )
    end
    return solution
end

function independent_astar(mapf::MAPF, constraints)
    graph, edge_weights = mapf.graph, mapf.edge_weights
    A = nb_agents(mapf)
    solution = Vector{Path}(undef, A)
    for a in 1:A
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        forbidden_vertices = constraints[a]
        solution[a] = temporal_astar(
            graph,
            s,
            d,
            t0;
            edge_weights=edge_weights,
            forbidden_vertices=forbidden_vertices,
            heuristic=heuristic,
        )
    end
    return solution
end
