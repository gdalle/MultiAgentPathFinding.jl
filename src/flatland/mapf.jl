function build_conflict_groups(g::FlatlandGraph)
    grid = get_grid(g)
    h, w = size(grid)
    conflict_groups = Vector{Int}[]
    # Add cell groups
    for i in 1:h, j in 1:w
        grid[i, j] > 0 || continue
        group = vertices_on_cell(g, i, j)
        push!(conflict_groups, group)
    end
    # Add cell border groups
    for v in vertices(g)
        (_, _, _, kind) = get_label(g, v)
        kind == REAL || continue
        v_mirror = mirror_vertex(g, v)
        [v_mirror, v] in conflict_groups && continue
        group = [v, v_mirror]
        push!(conflict_groups, group)
    end
    return conflict_groups
end

function flatland_mapf(pyenv::Py)
    agents = [Agent(pyagent) for pyagent in pyenv.agents]
    g = flatland_graph(pyenv, agents)
    sources = [get_vertex(g, initial_label(agent)) for agent in agents]
    destinations = [get_vertex(g, target_label(agent)) for agent in agents]
    starting_times = [agent.earliest_departure for agent in agents]
    conflict_groups = build_conflict_groups(g)
    mapf = MAPF(;
        graph=g,
        sources=sources,
        destinations=destinations,
        starting_times=starting_times,
        conflict_groups=conflict_groups,
        edge_weights=weights(g),
    )
    return mapf
end
